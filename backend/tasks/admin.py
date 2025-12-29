from django.contrib import admin
from .models import CollectionTask


@admin.register(CollectionTask)
class CollectionTaskAdmin(admin.ModelAdmin):
    list_display = ('id', 'report', 'collector', 'status', 'priority', 'assigned_at', 'completed_at')
    list_filter = ('status', 'priority', 'assigned_at')
    search_fields = ('report__title', 'collector__username', 'notes')
    readonly_fields = ('assigned_at', 'updated_at')
    date_hierarchy = 'assigned_at'
