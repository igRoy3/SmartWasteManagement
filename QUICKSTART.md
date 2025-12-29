# Quick Start Guide

## Prerequisites

- Python 3.8+ installed
- Flutter SDK installed (for mobile app)
- Android Studio or Xcode (for mobile development)
- Git installed

## Quick Start - Backend

1. **Clone the repository:**
   ```bash
   git clone https://github.com/igRoy3/SmartWasteManagement.git
   cd SmartWasteManagement
   ```

2. **Set up backend:**
   ```bash
   cd backend
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Initialize database:**
   ```bash
   python manage.py migrate
   python manage.py createsuperuser
   ```

4. **Run server:**
   ```bash
   python manage.py runserver
   ```

5. **Access admin panel:**
   Open http://localhost:8000/admin

6. **View API documentation:**
   Open http://localhost:8000/swagger/

## Quick Start - Mobile App

1. **Navigate to mobile directory:**
   ```bash
   cd mobile
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update backend URL:**
   Edit `lib/utils/api_constants.dart` and change `baseUrl` to your backend server URL

4. **Run the app:**
   ```bash
   flutter run
   ```

## Testing the System

### Create Test Users

1. **Create Admin:**
   ```bash
   python manage.py shell
   ```
   ```python
   from accounts.models import User
   User.objects.create_user('admin', 'admin@test.com', 'admin123', role='admin')
   ```

2. **Create Collector:**
   ```python
   User.objects.create_user('collector1', 'collector@test.com', 'collector123', role='collector')
   ```

3. **Create Citizen:**
   ```python
   User.objects.create_user('citizen1', 'citizen@test.com', 'citizen123', role='citizen')
   ```

### Test Workflow

1. **Citizen Flow:**
   - Login with citizen credentials
   - Create a new garbage report
   - Upload a photo
   - Add location
   - Submit report

2. **Admin Flow:**
   - Login with admin credentials
   - View all reports
   - Assign a report to a collector
   - Track status

3. **Collector Flow:**
   - Login with collector credentials
   - View assigned tasks
   - Start a task
   - Navigate to location
   - Mark task as completed

## Common Issues

### Backend Issues

**Issue: ModuleNotFoundError**
- Solution: Make sure virtual environment is activated and dependencies are installed

**Issue: Database errors**
- Solution: Run `python manage.py migrate`

**Issue: CORS errors**
- Solution: Check CORS_ALLOWED_ORIGINS in settings.py

### Mobile App Issues

**Issue: Cannot connect to backend**
- Solution: Update API URL in `lib/utils/api_constants.dart`

**Issue: Location permission denied**
- Solution: Grant location permissions in phone settings

**Issue: Camera not working**
- Solution: Grant camera permissions in phone settings

## Next Steps

1. Configure Google Maps API key for better map features
2. Set up PostgreSQL for production
3. Configure push notifications
4. Add more features as needed

## Support

For issues and questions:
- Check the main README.md
- Review API_DOCUMENTATION.md
- Create an issue on GitHub

## Useful Commands

### Backend
```bash
# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run tests
python manage.py test

# Collect static files
python manage.py collectstatic
```

### Mobile
```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Build APK
flutter build apk

# Run tests
flutter test

# Analyze code
flutter analyze
```
