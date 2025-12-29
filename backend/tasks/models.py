from django.db import models
from django.conf import settings
from reports.models import GarbageReport


class CollectionTask(models.Model):
    """Model for garbage collection tasks assigned to collectors."""
    STATUS_CHOICES = (
        ('assigned', 'Assigned'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    )
    
    PRIORITY_CHOICES = (
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    )
    
    report = models.OneToOneField(
        GarbageReport,
        on_delete=models.CASCADE,
        related_name='collection_task'
    )
    collector = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='collection_tasks',
        limit_choices_to={'role': 'collector'}
    )
    assigned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='assigned_tasks'
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='assigned')
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    notes = models.TextField(blank=True, null=True)
    completion_notes = models.TextField(blank=True, null=True)
    
    # Timestamps
    assigned_at = models.DateTimeField(auto_now_add=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-assigned_at']
    
    def __str__(self):
        return f"Task #{self.id} - {self.report.title} assigned to {self.collector.username}"
