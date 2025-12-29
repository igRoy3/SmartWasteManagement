from rest_framework import serializers
from django.utils import timezone
from .models import CollectionTask
from reports.serializers import GarbageReportSerializer
from accounts.serializers import UserSerializer


class CollectionTaskSerializer(serializers.ModelSerializer):
    """Serializer for collection tasks."""
    report = GarbageReportSerializer(read_only=True)
    collector = UserSerializer(read_only=True)
    assigned_by = UserSerializer(read_only=True)
    
    class Meta:
        model = CollectionTask
        fields = ('id', 'report', 'collector', 'assigned_by', 'status', 
                  'priority', 'notes', 'completion_notes', 'assigned_at', 
                  'started_at', 'completed_at', 'updated_at')
        read_only_fields = ('id', 'assigned_at', 'updated_at')


class CollectionTaskCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating collection tasks."""
    
    class Meta:
        model = CollectionTask
        fields = ('report', 'collector', 'priority', 'notes')
    
    def validate_report(self, value):
        """Ensure report doesn't already have a task."""
        if hasattr(value, 'collection_task'):
            raise serializers.ValidationError("This report already has a collection task assigned.")
        return value


class CollectionTaskUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating collection task status."""
    
    class Meta:
        model = CollectionTask
        fields = ('status', 'completion_notes')
    
    def update(self, instance, validated_data):
        status = validated_data.get('status', instance.status)
        
        # Update timestamps based on status
        if status == 'in_progress' and instance.status != 'in_progress':
            instance.started_at = timezone.now()
        elif status == 'completed' and instance.status != 'completed':
            instance.completed_at = timezone.now()
            # Update report status as well
            instance.report.status = 'completed'
            instance.report.save()
        
        return super().update(instance, validated_data)
