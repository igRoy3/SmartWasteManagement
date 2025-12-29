from django.db import models
from django.conf import settings


class GarbageReport(models.Model):
    """Model for garbage reports submitted by citizens."""
    
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        ASSIGNED = 'assigned', 'Assigned'
        IN_PROGRESS = 'in_progress', 'In Progress'
        COMPLETED = 'completed', 'Completed'
        REJECTED = 'rejected', 'Rejected'
    
    class WasteType(models.TextChoices):
        ORGANIC = 'organic', 'Organic Waste'
        RECYCLABLE = 'recyclable', 'Recyclable Waste'
        HAZARDOUS = 'hazardous', 'Hazardous Waste'
        ELECTRONIC = 'electronic', 'Electronic Waste'
        MIXED = 'mixed', 'Mixed Waste'
    
    # Report details
    title = models.CharField(max_length=200)
    description = models.TextField()
    waste_type = models.CharField(
        max_length=20,
        choices=WasteType.choices,
        default=WasteType.MIXED
    )
    
    # Location
    latitude = models.DecimalField(max_digits=15, decimal_places=10)
    longitude = models.DecimalField(max_digits=15, decimal_places=10)
    address = models.TextField()
    
    # Image
    image = models.ImageField(upload_to='reports/')
    
    # Status tracking
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING
    )
    
    # Relationships
    reported_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reports'
    )
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_tasks'
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} - {self.status}"


class ReportUpdate(models.Model):
    """Model to track status updates for a report."""
    
    report = models.ForeignKey(
        GarbageReport,
        on_delete=models.CASCADE,
        related_name='updates'
    )
    status = models.CharField(
        max_length=20,
        choices=GarbageReport.Status.choices
    )
    note = models.TextField(blank=True, null=True)
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.report.title} - {self.status}"
