from django.db import models
from django.conf import settings


class GarbageReport(models.Model):
    """Model for garbage reports submitted by citizens."""
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('assigned', 'Assigned'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('rejected', 'Rejected'),
    )
    
    GARBAGE_TYPE_CHOICES = (
        ('household', 'Household Waste'),
        ('recyclable', 'Recyclable'),
        ('hazardous', 'Hazardous'),
        ('electronic', 'Electronic Waste'),
        ('construction', 'Construction Debris'),
        ('other', 'Other'),
    )
    
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reports'
    )
    title = models.CharField(max_length=200)
    description = models.TextField()
    garbage_type = models.CharField(max_length=20, choices=GARBAGE_TYPE_CHOICES, default='household')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Location
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    address = models.TextField()
    
    # Images
    image = models.ImageField(upload_to='garbage_reports/', null=True, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} - {self.status}"


class ReportComment(models.Model):
    """Comments on garbage reports."""
    report = models.ForeignKey(
        GarbageReport,
        on_delete=models.CASCADE,
        related_name='comments'
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Comment by {self.user.username} on {self.report.title}"
