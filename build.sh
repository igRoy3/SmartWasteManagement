#!/usr/bin/env bash
# exit on error
set -o errexit

# Install Python dependencies
pip install -r requirements.txt

# Collect static files
python manage.py collectstatic --no-input

# Apply database migrations
python manage.py migrate

# Delete and recreate admin user with proper permissions
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()

# Delete existing admin if exists
User.objects.filter(username='admin').delete()

# Create new admin with all permissions
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
print('Admin user recreated with full permissions')
EOF
