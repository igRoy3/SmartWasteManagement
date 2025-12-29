# Smart Waste Management System

A comprehensive smart waste management system with Flutter mobile apps and Django backend for reporting, assigning, and tracking garbage collection tasks in real-time.

## 🌟 Features

### Citizen App
- 📱 Report garbage with photos and location
- 📍 GPS-based location detection
- 📊 Track report status updates
- 🔔 Push notification support
- 👤 User registration and profile management

### Collector App
- 📋 View assigned collection tasks
- 🗺️ **Route optimization** - Plan optimal collection routes
- 📸 Before/after photo documentation
- ✅ Mark tasks as complete
- 🧭 Navigation integration with Google Maps

### Admin Dashboard
- 📊 **Enhanced analytics dashboard** with 8+ chart types
- 📈 Trends and performance metrics
- 🗺️ Map-based report visualization
- 👥 Collector management
- 📝 Report assignment and status management

### Backend
- 🔐 JWT authentication
- 🔄 **WebSocket support** for real-time updates
- 📲 **Push notification** infrastructure (FCM)
- 📊 Advanced analytics API
- 🚀 Production-ready with Heroku deployment config

## 🛠️ Tech Stack

### Frontend
- **Mobile**: Flutter 3.x
- **Admin Dashboard**: HTML5, CSS3, JavaScript, Chart.js, Leaflet.js

### Backend
- **Framework**: Django 6.0 + Django REST Framework
- **WebSockets**: Django Channels + Daphne
- **Database**: SQLite (dev) / PostgreSQL (production)
- **Push Notifications**: Firebase Cloud Messaging

## 📱 Screenshots

*Coming soon*

## 🚀 Quick Start

### Prerequisites
- Python 3.12+
- Flutter SDK 3.x
- Node.js (optional, for admin dashboard serving)

### Backend Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/SmartWasteManagement.git
cd SmartWasteManagement

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run server
python manage.py runserver
```

### Citizen App Setup

```bash
cd citizen_app
flutter pub get
flutter run
```

### Collector App Setup

```bash
cd collector_app
flutter pub get
flutter run
```

### Admin Dashboard

Open `admin-dashboard/index.html` in a browser, or serve with:

```bash
cd admin-dashboard
python -m http.server 3000
```

## 📋 API Endpoints

### Authentication
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - User login
- `POST /api/auth/logout/` - User logout
- `GET /api/auth/profile/` - Get/update profile
- `POST /api/auth/fcm-token/` - Register FCM token

### Reports
- `POST /api/reports/` - Create report
- `GET /api/reports/` - List user's reports
- `GET /api/reports/{id}/` - Report details

### Admin
- `GET /api/reports/admin/dashboard/` - Dashboard stats
- `GET /api/reports/admin/analytics/` - Enhanced analytics
- `GET /api/reports/admin/reports/` - All reports
- `POST /api/reports/admin/reports/{id}/assign/` - Assign collector

### Collector
- `GET /api/reports/collector/tasks/` - Assigned tasks
- `POST /api/reports/collector/tasks/{id}/update-status/` - Update status

### WebSocket
- `ws://host/ws/reports/` - Real-time report updates
- `ws://host/ws/dashboard/` - Admin dashboard updates

## 🔧 Configuration

Copy `.env.example` to `.env` and configure:

```env
SECRET_KEY=your-secret-key
DEBUG=True
DATABASE_URL=sqlite:///db.sqlite3
REDIS_URL=redis://localhost:6379/0
FCM_CREDENTIALS_PATH=/path/to/firebase-credentials.json
```

## 📦 Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions including:
- Heroku deployment
- Release APK building
- Firebase setup
- Production configuration

## 🧪 Test Accounts

For development testing:
- **Admin**: admin / admin123
- **Citizen**: citizen1 / citizen123
- **Collector**: collector1 / collector123

## 📊 Analytics Dashboard

The enhanced analytics includes:
- Reports by status (doughnut chart)
- Reports by waste type (pie chart)
- Daily reports trend (line chart)
- Hourly distribution (bar chart)
- Weekly distribution (bar chart)
- Completion rate trend (line chart)
- Collector performance (stacked bar)
- Top collectors leaderboard

## 🔄 Real-time Updates

The system supports real-time updates via WebSockets:
- Report status changes
- New task assignments
- Dashboard statistics updates

## 📱 Push Notifications

Firebase Cloud Messaging integration for:
- New task notifications (collectors)
- Status update notifications (citizens)
- Topic-based broadcasts

## 🗺️ Route Optimization

Collectors can plan optimal routes using:
- Nearest neighbor algorithm
- Multi-stop route planning
- Google Maps navigation integration
- Distance estimation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

Built with ❤️ for smart city initiatives
