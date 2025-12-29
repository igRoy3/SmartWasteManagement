from django.contrib import admin
from .models import GarbageReport, ReportUpdate


@admin.register(GarbageReport)
class GarbageReportAdmin(admin.ModelAdmin):
    list_display = ['title', 'waste_type', 'status', 'reported_by', 'assigned_to', 'created_at']
    list_filter = ['status', 'waste_type', 'created_at']
    search_fields = ['title', 'description', 'address']
    readonly_fields = ['created_at', 'updated_at', 'completed_at']
    ordering = ['-created_at']


@admin.register(ReportUpdate)
class ReportUpdateAdmin(admin.ModelAdmin):
    list_display = ['report', 'status', 'updated_by', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['report__title', 'note']
    readonly_fields = ['created_at']
    ordering = ['-created_at']
