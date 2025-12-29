# Smart Waste Management System

A comprehensive smart waste management system with a Django backend and Flutter mobile app for reporting, assigning, and tracking garbage collection tasks.

## Features

### For Citizens
- Report garbage with photo and location
- Track status of submitted reports
- View report history
- Real-time location capture

### For Admins
- View all garbage reports
- Assign tasks to collectors
- Track collection progress
- Monitor system statistics

### For Collectors
- View assigned collection tasks
- Navigate to collection locations
- Update task status (start, complete)
- View task priorities and notes

## Tech Stack

### Backend (Django)
- Django 4.2+
- Django REST Framework
- JWT Authentication (Simple JWT)
- PostgreSQL/SQLite database
- API documentation with drf-yasg

### Frontend (Flutter)
- Flutter 3.0+
- Provider for state management
- HTTP & Dio for API calls
- Google Maps integration
- Image picker for photos
- Geolocator for location services

## Project Structure

```
SmartWasteManagement/
├── backend/                 # Django backend
│   ├── accounts/           # User management & authentication
│   ├── reports/            # Garbage report management
│   ├── tasks/              # Collection task management
│   ├── smart_waste/        # Project settings
│   └── requirements.txt    # Python dependencies
│
└── mobile/                 # Flutter mobile app
    ├── lib/
    │   ├── models/         # Data models
    │   ├── screens/        # UI screens
    │   ├── services/       # API services
    │   └── utils/          # Utilities
    └── pubspec.yaml        # Flutter dependencies
```

## Setup Instructions

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run migrations:**
   ```bash
   python manage.py migrate
   ```

5. **Create superuser:**
   ```bash
   python manage.py createsuperuser
   ```

6. **Run development server:**
   ```bash
   python manage.py runserver
   ```

The backend will be available at `http://localhost:8000`

### Frontend Setup

1. **Navigate to mobile directory:**
   ```bash
   cd mobile
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update API URL:**
   - Edit `lib/utils/api_constants.dart`
   - Update `baseUrl` to your backend URL

4. **Add Google Maps API Key (Optional):**
   - Get an API key from Google Cloud Console
   - Update `AndroidManifest.xml` with your key

5. **Run the app:**
   ```bash
   flutter run
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - User login (returns JWT tokens)
- `POST /api/auth/token/refresh/` - Refresh access token
- `GET /api/auth/profile/` - Get user profile
- `PUT /api/auth/profile/update/` - Update user profile

### Reports
- `GET /api/reports/` - List all reports
- `POST /api/reports/` - Create new report
- `GET /api/reports/{id}/` - Get report details
- `GET /api/reports/my-reports/` - Get current user's reports
- `PUT /api/reports/{id}/` - Update report status (admin only)

### Tasks
- `GET /api/tasks/` - List all tasks
- `POST /api/tasks/` - Create new task (admin only)
- `GET /api/tasks/{id}/` - Get task details
- `PATCH /api/tasks/{id}/` - Update task status
- `GET /api/tasks/my-tasks/` - Get collector's assigned tasks

### API Documentation
- Swagger UI: `http://localhost:8000/swagger/`
- ReDoc: `http://localhost:8000/redoc/`

## User Roles

1. **Citizen** - Can create and view their own garbage reports
2. **Admin** - Can view all reports, assign tasks to collectors
3. **Collector** - Can view assigned tasks and update their status

## Environment Variables

Create a `.env` file in the backend directory:

```
SECRET_KEY=your-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=sqlite:///db.sqlite3
```

## Development

### Running Tests
```bash
# Backend tests
cd backend
python manage.py test

# Flutter tests
cd mobile
flutter test
```

### Code Quality
```bash
# Python linting
flake8 backend/

# Flutter analysis
flutter analyze
```

## Deployment

### Backend Deployment (Example with Heroku)
1. Install Heroku CLI
2. Create Heroku app
3. Set environment variables
4. Push to Heroku
5. Run migrations on Heroku

### Mobile App Deployment
1. **Android:**
   ```bash
   flutter build apk --release
   ```

2. **iOS:**
   ```bash
   flutter build ios --release
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions, please create an issue in the GitHub repository.

## Acknowledgments

- Django REST Framework for the excellent API framework
- Flutter team for the amazing cross-platform framework
- All contributors to the open-source libraries used in this project
