"""
Push notification service using Firebase Cloud Messaging.
"""
import os
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

# Firebase Admin SDK initialization
firebase_app = None

def initialize_firebase():
    """Initialize Firebase Admin SDK."""
    global firebase_app
    
    if firebase_app is not None:
        return firebase_app
    
    try:
        import firebase_admin
        from firebase_admin import credentials
        
        cred_path = getattr(settings, 'FCM_CREDENTIALS_PATH', None)
        
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_app = firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialized successfully")
        else:
            logger.warning("Firebase credentials not found. Push notifications disabled.")
    except ImportError:
        logger.warning("firebase-admin not installed. Push notifications disabled.")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
    
    return firebase_app


def send_push_notification(token, title, body, data=None):
    """
    Send a push notification to a single device.
    
    Args:
        token: FCM device token
        title: Notification title
        body: Notification body
        data: Optional dictionary of additional data
    
    Returns:
        bool: True if sent successfully, False otherwise
    """
    if not initialize_firebase():
        return False
    
    try:
        from firebase_admin import messaging
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=token,
        )
        
        response = messaging.send(message)
        logger.info(f"Push notification sent: {response}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to send push notification: {e}")
        return False


def send_push_notification_to_multiple(tokens, title, body, data=None):
    """
    Send a push notification to multiple devices.
    
    Args:
        tokens: List of FCM device tokens
        title: Notification title
        body: Notification body
        data: Optional dictionary of additional data
    
    Returns:
        int: Number of successful sends
    """
    if not initialize_firebase():
        return 0
    
    if not tokens:
        return 0
    
    try:
        from firebase_admin import messaging
        
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            tokens=tokens,
        )
        
        response = messaging.send_multicast(message)
        logger.info(
            f"Push notifications sent: {response.success_count} success, "
            f"{response.failure_count} failed"
        )
        return response.success_count
        
    except Exception as e:
        logger.error(f"Failed to send push notifications: {e}")
        return 0


def send_topic_notification(topic, title, body, data=None):
    """
    Send a push notification to all devices subscribed to a topic.
    
    Args:
        topic: Topic name (e.g., 'collectors', 'admins')
        title: Notification title
        body: Notification body
        data: Optional dictionary of additional data
    
    Returns:
        bool: True if sent successfully, False otherwise
    """
    if not initialize_firebase():
        return False
    
    try:
        from firebase_admin import messaging
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            topic=topic,
        )
        
        response = messaging.send(message)
        logger.info(f"Topic notification sent to {topic}: {response}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to send topic notification: {e}")
        return False


# Notification helper functions for common use cases

def notify_new_assignment(collector_token, report_title, report_id):
    """Notify a collector of a new assignment."""
    return send_push_notification(
        token=collector_token,
        title="New Task Assigned",
        body=f"You have been assigned to collect: {report_title}",
        data={
            'type': 'new_assignment',
            'report_id': str(report_id),
        }
    )


def notify_status_update(citizen_token, report_title, new_status, report_id):
    """Notify a citizen of a status update on their report."""
    status_messages = {
        'assigned': 'has been assigned to a collector',
        'in_progress': 'collection is now in progress',
        'completed': 'has been completed!',
        'rejected': 'has been rejected',
    }
    
    message = status_messages.get(new_status, f'status changed to {new_status}')
    
    return send_push_notification(
        token=citizen_token,
        title="Report Status Updated",
        body=f"Your report '{report_title}' {message}",
        data={
            'type': 'status_update',
            'report_id': str(report_id),
            'status': new_status,
        }
    )


def notify_all_collectors(title, body, data=None):
    """Send notification to all collectors via topic."""
    return send_topic_notification('collectors', title, body, data)
