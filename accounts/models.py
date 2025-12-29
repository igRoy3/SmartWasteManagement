from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Custom user model with role-based access."""
    
    class Role(models.TextChoices):
        CITIZEN = 'citizen', 'Citizen'
        COLLECTOR = 'collector', 'Collector'
        ADMIN = 'admin', 'Admin'
    
    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.CITIZEN
    )
    phone = models.CharField(max_length=15, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    profile_picture = models.ImageField(
        upload_to='profiles/',
        blank=True,
        null=True
    )
    # FCM token for push notifications
    fcm_token = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.username} ({self.role})"

    @property
    def is_citizen(self):
        return self.role == self.Role.CITIZEN

    @property
    def is_collector(self):
        return self.role == self.Role.COLLECTOR

    @property
    def is_admin_user(self):
        return self.role == self.Role.ADMIN

