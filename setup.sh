#!/bin/bash

# Smart Waste Management - Setup Script
# This script sets up the development environment

set -e

echo "========================================"
echo "Smart Waste Management - Setup Script"
echo "========================================"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

echo "✓ Python 3 found: $(python3 --version)"

# Setup Backend
echo ""
echo "Setting up Django Backend..."
echo "--------------------"

cd backend

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt > /dev/null 2>&1

echo "✓ Dependencies installed"

# Run migrations
echo "Running database migrations..."
python manage.py migrate

echo "✓ Migrations complete"

# Create superuser if it doesn't exist
echo ""
echo "Creating admin user..."
echo "from accounts.models import User; User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@smartwaste.com', 'admin123', role='admin')" | python manage.py shell

# Create test users
echo "Creating test users..."
echo "from accounts.models import User; User.objects.filter(username='citizen1').exists() or User.objects.create_user('citizen1', 'citizen@test.com', 'citizen123', role='citizen')" | python manage.py shell
echo "from accounts.models import User; User.objects.filter(username='collector1').exists() or User.objects.create_user('collector1', 'collector@test.com', 'collector123', role='collector')" | python manage.py shell

echo "✓ Test users created"

cd ..

echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Test Credentials:"
echo "  Admin:     username: admin      password: admin123"
echo "  Citizen:   username: citizen1   password: citizen123"
echo "  Collector: username: collector1 password: collector123"
echo ""
echo "To start the backend server:"
echo "  cd backend"
echo "  source venv/bin/activate"
echo "  python manage.py runserver"
echo ""
echo "Backend will be available at: http://localhost:8000"
echo "Admin panel: http://localhost:8000/admin"
echo "API docs: http://localhost:8000/swagger/"
echo ""
echo "For mobile app setup, see QUICKSTART.md"
echo "========================================"
