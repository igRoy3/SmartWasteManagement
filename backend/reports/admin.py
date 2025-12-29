from django.contrib import admin
from .models import GarbageReport, ReportComment


@admin.register(GarbageReport)
class GarbageReportAdmin(admin.ModelAdmin):
    list_display = ('title', 'reporter', 'garbage_type', 'status', 'created_at')
    list_filter = ('status', 'garbage_type', 'created_at')
    search_fields = ('title', 'description', 'reporter__username')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(ReportComment)
class ReportCommentAdmin(admin.ModelAdmin):
    list_display = ('report', 'user', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('comment', 'user__username', 'report__title')
