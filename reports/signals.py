"""
Django signals for broadcasting WebSocket updates.
"""
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .models import GarbageReport


# Store previous status for comparison
_previous_status = {}


@receiver(pre_save, sender=GarbageReport)
def store_previous_status(sender, instance, **kwargs):
    """Store the previous status before saving."""
    if instance.pk:
        try:
            old_instance = GarbageReport.objects.get(pk=instance.pk)
            _previous_status[instance.pk] = {
                'status': old_instance.status,
                'collector_id': old_instance.collector_id
            }
        except GarbageReport.DoesNotExist:
            pass


@receiver(post_save, sender=GarbageReport)
def broadcast_report_update(sender, instance, created, **kwargs):
    """Broadcast report updates via WebSocket."""
    channel_layer = get_channel_layer()
    if not channel_layer:
        return
    
    # Prepare report data for broadcasting
    report_data = {
        'id': instance.id,
        'title': instance.title,
        'status': instance.status,
        'waste_type': instance.waste_type,
        'latitude': str(instance.latitude) if instance.latitude else None,
        'longitude': str(instance.longitude) if instance.longitude else None,
        'created_at': instance.created_at.isoformat() if instance.created_at else None,
        'reporter_id': instance.reporter_id,
        'collector_id': instance.collector_id,
    }
    
    if created:
        # New report created
        # Notify admins
        async_to_sync(channel_layer.group_send)(
            'dashboard_updates',
            {
                'type': 'report_update',
                'report': report_data,
                'action': 'created'
            }
        )
        
        # Notify general updates channel
        async_to_sync(channel_layer.group_send)(
            'report_updates',
            {
                'type': 'report_created',
                'report': report_data
            }
        )
    else:
        # Report updated
        previous = _previous_status.pop(instance.pk, {})
        old_status = previous.get('status')
        old_collector_id = previous.get('collector_id')
        
        # Notify admins of any update
        async_to_sync(channel_layer.group_send)(
            'dashboard_updates',
            {
                'type': 'report_update',
                'report': report_data,
                'action': 'updated'
            }
        )
        
        # Notify the reporter
        if instance.reporter_id:
            async_to_sync(channel_layer.group_send)(
                f'user_{instance.reporter_id}',
                {
                    'type': 'report_updated',
                    'report': report_data
                }
            )
        
        # Handle assignment
        if instance.collector_id and instance.collector_id != old_collector_id:
            # Notify the assigned collector
            async_to_sync(channel_layer.group_send)(
                f'user_{instance.collector_id}',
                {
                    'type': 'task_update',
                    'task': report_data
                }
            )
            
            # Also notify collector updates channel
            async_to_sync(channel_layer.group_send)(
                'collector_updates',
                {
                    'type': 'report_assigned',
                    'report': report_data,
                    'collector_id': instance.collector_id
                }
            )
            
            # Notify user of assignment
            async_to_sync(channel_layer.group_send)(
                f'user_{instance.collector_id}',
                {
                    'type': 'notification',
                    'title': 'New Task Assigned',
                    'message': f'You have been assigned to: {instance.title}',
                    'data': {'report_id': instance.id}
                }
            )
        
        # Handle status change
        if old_status and instance.status != old_status:
            # Notify the reporter of status change
            if instance.reporter_id:
                status_messages = {
                    'assigned': 'Your report has been assigned to a collector',
                    'in_progress': 'Collection is now in progress',
                    'completed': 'Your report has been completed!',
                    'rejected': 'Your report has been rejected'
                }
                message = status_messages.get(
                    instance.status, 
                    f'Status changed to {instance.status}'
                )
                
                async_to_sync(channel_layer.group_send)(
                    f'user_{instance.reporter_id}',
                    {
                        'type': 'notification',
                        'title': 'Report Status Updated',
                        'message': message,
                        'data': {'report_id': instance.id, 'status': instance.status}
                    }
                )
        
        # Notify subscribers of specific report
        async_to_sync(channel_layer.group_send)(
            f'report_{instance.pk}',
            {
                'type': 'report_updated',
                'report': report_data
            }
        )
