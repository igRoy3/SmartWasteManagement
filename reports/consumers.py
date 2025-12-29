"""
WebSocket consumers for real-time updates.
"""
import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model

User = get_user_model()


class ReportUpdateConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for real-time report updates.
    
    Clients can connect to receive updates about:
    - New reports being created
    - Status changes on reports
    - Assignment updates
    """
    
    async def connect(self):
        self.user = self.scope.get('user')
        self.user_role = None
        self.user_id = None
        
        # Get user info if authenticated
        if self.user and self.user.is_authenticated:
            self.user_id = self.user.id
            self.user_role = await self.get_user_role()
        
        # Join the general updates group
        await self.channel_layer.group_add(
            'report_updates',
            self.channel_name
        )
        
        # Join role-specific group
        if self.user_role:
            await self.channel_layer.group_add(
                f'{self.user_role}_updates',
                self.channel_name
            )
        
        # Join user-specific group
        if self.user_id:
            await self.channel_layer.group_add(
                f'user_{self.user_id}',
                self.channel_name
            )
        
        await self.accept()
        
        # Send connection confirmation
        await self.send(text_data=json.dumps({
            'type': 'connection_established',
            'message': 'Connected to real-time updates',
            'user_role': self.user_role
        }))
    
    async def disconnect(self, close_code):
        # Leave all groups
        await self.channel_layer.group_discard(
            'report_updates',
            self.channel_name
        )
        
        if self.user_role:
            await self.channel_layer.group_discard(
                f'{self.user_role}_updates',
                self.channel_name
            )
        
        if self.user_id:
            await self.channel_layer.group_discard(
                f'user_{self.user_id}',
                self.channel_name
            )
    
    async def receive(self, text_data):
        """Handle incoming WebSocket messages (e.g., subscribe to specific reports)"""
        try:
            data = json.loads(text_data)
            action = data.get('action')
            
            if action == 'subscribe_report':
                report_id = data.get('report_id')
                if report_id:
                    await self.channel_layer.group_add(
                        f'report_{report_id}',
                        self.channel_name
                    )
                    await self.send(text_data=json.dumps({
                        'type': 'subscribed',
                        'report_id': report_id
                    }))
            
            elif action == 'unsubscribe_report':
                report_id = data.get('report_id')
                if report_id:
                    await self.channel_layer.group_discard(
                        f'report_{report_id}',
                        self.channel_name
                    )
            
            elif action == 'ping':
                await self.send(text_data=json.dumps({
                    'type': 'pong',
                    'timestamp': data.get('timestamp')
                }))
                
        except json.JSONDecodeError:
            pass
    
    # Event handlers for group messages
    
    async def report_created(self, event):
        """Handle new report creation event"""
        await self.send(text_data=json.dumps({
            'type': 'report_created',
            'report': event['report']
        }))
    
    async def report_updated(self, event):
        """Handle report status update event"""
        await self.send(text_data=json.dumps({
            'type': 'report_updated',
            'report': event['report']
        }))
    
    async def report_assigned(self, event):
        """Handle report assignment event"""
        await self.send(text_data=json.dumps({
            'type': 'report_assigned',
            'report': event['report'],
            'collector_id': event.get('collector_id')
        }))
    
    async def task_update(self, event):
        """Handle task update for collectors"""
        await self.send(text_data=json.dumps({
            'type': 'task_update',
            'task': event['task']
        }))
    
    async def notification(self, event):
        """Handle general notifications"""
        await self.send(text_data=json.dumps({
            'type': 'notification',
            'title': event.get('title'),
            'message': event.get('message'),
            'data': event.get('data', {})
        }))
    
    @database_sync_to_async
    def get_user_role(self):
        """Get user role from database"""
        try:
            user = User.objects.get(id=self.user.id)
            return user.role
        except User.DoesNotExist:
            return None


class DashboardConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for admin dashboard real-time updates.
    """
    
    async def connect(self):
        self.user = self.scope.get('user')
        
        # Only allow admin users
        if not self.user or not self.user.is_authenticated:
            await self.close()
            return
        
        user_role = await self.get_user_role()
        if user_role != 'admin':
            await self.close()
            return
        
        # Join admin dashboard group
        await self.channel_layer.group_add(
            'dashboard_updates',
            self.channel_name
        )
        
        await self.accept()
        
        await self.send(text_data=json.dumps({
            'type': 'connection_established',
            'message': 'Connected to dashboard updates'
        }))
    
    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            'dashboard_updates',
            self.channel_name
        )
    
    async def receive(self, text_data):
        """Handle incoming messages"""
        try:
            data = json.loads(text_data)
            if data.get('action') == 'ping':
                await self.send(text_data=json.dumps({
                    'type': 'pong'
                }))
        except json.JSONDecodeError:
            pass
    
    async def stats_update(self, event):
        """Handle stats update event"""
        await self.send(text_data=json.dumps({
            'type': 'stats_update',
            'stats': event['stats']
        }))
    
    async def report_update(self, event):
        """Handle report update event"""
        await self.send(text_data=json.dumps({
            'type': 'report_update',
            'report': event['report'],
            'action': event.get('action', 'updated')
        }))
    
    @database_sync_to_async
    def get_user_role(self):
        """Get user role from database"""
        try:
            user = User.objects.get(id=self.user.id)
            return user.role
        except User.DoesNotExist:
            return None
