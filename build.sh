#!/usr/bin/env bash
# exit on error
set -o errexit

# Install Python dependencies
pip install -r requirements.txt

# Collect static files
python manage.py collectstatic --no-input

# Apply database migrations
python manage.py migrate

# Create superuser with full permissions if it doesn't exist
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    admin = User.objects.create_superuser(
        username='admin',
        email='admin@wastemanagement.com',
        password='admin123',
        first_name='Admin',
        last_name='User'
    )
    admin.is_staff = True
    admin.is_superuser = True
    admin.is_admin = True
    admin.save()
    print('Superuser created successfully with full permissions')
else:
    # Update existing admin user to ensure proper permissions
    admin = User.objects.get(username='admin')
    admin.is_staff = True
    admin.is_superuser = True
    admin.is_admin = True
    admin.save()
    print('Admin user permissions updated')
EOF
