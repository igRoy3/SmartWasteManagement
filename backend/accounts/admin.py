from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('username', 'email', 'role', 'first_name', 'last_name', 'is_staff')
    list_filter = ('role', 'is_staff', 'is_superuser', 'is_active')
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Custom Fields', {'fields': ('role', 'phone_number', 'address', 'profile_image')}),
    )
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('Custom Fields', {'fields': ('role', 'phone_number', 'address')}),
    )
