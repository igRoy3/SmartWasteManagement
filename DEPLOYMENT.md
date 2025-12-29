# Deployment Guide

This guide covers deploying the Smart Waste Management System to production.

## Backend Deployment (Heroku)

### Prerequisites
- Heroku CLI installed
- Git repository initialized
- Heroku account

### Step 1: Create Heroku App

```bash
heroku login
heroku create smart-waste-backend
```

### Step 2: Add PostgreSQL Database

```bash
heroku addons:create heroku-postgresql:essential-0
```

### Step 3: Add Redis (for WebSockets)

```bash
heroku addons:create heroku-redis:mini
```

### Step 4: Set Environment Variables

```bash
heroku config:set SECRET_KEY="$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')"
heroku config:set DEBUG=False
heroku config:set ALLOWED_HOSTS=smart-waste-backend.herokuapp.com
heroku config:set DJANGO_SETTINGS_MODULE=backend.settings_production
heroku config:set CORS_ALLOWED_ORIGINS=https://your-frontend-domain.com
```

### Step 5: Deploy

```bash
git push heroku main
```

### Step 6: Run Migrations

```bash
heroku run python manage.py migrate
heroku run python manage.py createsuperuser
```

### Step 7: Collect Static Files

```bash
heroku run python manage.py collectstatic --noinput
```

---

## Mobile App Build (Android)

### Prerequisites
- Flutter SDK installed
- Android Studio with SDK
- Java JDK 11+

### Step 1: Update API Base URL

Edit the constants file to point to your production backend:

**Citizen App**: `citizen_app/lib/utils/constants.dart`
**Collector App**: `collector_app/lib/utils/constants.dart`

```dart
static const String baseUrl = 'https://smart-waste-backend.herokuapp.com/api';
```

### Step 2: Create Keystore (First time only)

```bash
keytool -genkey -v -keystore ~/smart-waste-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias smart-waste
```

### Step 3: Configure Signing

Create `android/key.properties` in each app:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=smart-waste
storeFile=/path/to/smart-waste-key.jks
```

### Step 4: Build Release APK

**Citizen App:**
```bash
cd citizen_app
flutter build apk --release
```

APK location: `citizen_app/build/app/outputs/flutter-apk/app-release.apk`

**Collector App:**
```bash
cd collector_app
flutter build apk --release
```

APK location: `collector_app/build/app/outputs/flutter-apk/app-release.apk`

### Step 5: Build App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

---

## Admin Dashboard Deployment

The admin dashboard is a static HTML/JS/CSS application.

### Option 1: Host on Heroku (same as backend)

Add the dashboard files to Django's static files and configure nginx or whitenoise.

### Option 2: Netlify/Vercel (Recommended)

1. Create a new site on Netlify/Vercel
2. Point to the `admin-dashboard` folder
3. Update API URLs in `js/api.js`:
   ```javascript
   const API_BASE_URL = 'https://smart-waste-backend.herokuapp.com/api';
   ```
4. Deploy

### Option 3: GitHub Pages

1. Create a new repository for the dashboard
2. Enable GitHub Pages
3. Update API URLs and deploy

---

## Firebase Setup (Push Notifications)

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Add Android apps for both Citizen and Collector apps

### Step 2: Download Configuration

1. Download `google-services.json` for each app
2. Place in `android/app/` folder of each Flutter project

### Step 3: Get Server Key

1. Go to Project Settings > Cloud Messaging
2. Download the service account JSON file
3. Upload to Heroku or set as environment variable

### Step 4: Configure Backend

```bash
heroku config:set FCM_CREDENTIALS_PATH=/app/firebase-credentials.json
```

Or upload the JSON content:
```bash
heroku config:set GOOGLE_APPLICATION_CREDENTIALS_JSON='{"type":"service_account",...}'
```

---

## WebSocket Configuration

For production WebSockets with Heroku:

1. Ensure Redis addon is provisioned
2. The `settings_production.py` will automatically use Redis for channel layers
3. Update mobile apps to use `wss://` instead of `ws://`

---

## Environment Variables Summary

| Variable | Description | Example |
|----------|-------------|---------|
| `SECRET_KEY` | Django secret key | Random 50+ char string |
| `DEBUG` | Debug mode | `False` |
| `ALLOWED_HOSTS` | Allowed hostnames | `app.herokuapp.com` |
| `DATABASE_URL` | PostgreSQL URL | Auto-set by Heroku |
| `REDIS_URL` | Redis URL | Auto-set by Heroku |
| `CORS_ALLOWED_ORIGINS` | Allowed CORS origins | `https://frontend.com` |
| `FCM_CREDENTIALS_PATH` | Firebase credentials | `/app/credentials.json` |

---

## Post-Deployment Checklist

- [ ] Backend health check: `https://your-app.herokuapp.com/api/health/`
- [ ] Admin can login to dashboard
- [ ] Citizen app can register and login
- [ ] Collector app can login
- [ ] Reports can be created with images
- [ ] Map shows report locations
- [ ] Analytics dashboard loads charts
- [ ] Push notifications working (if configured)
- [ ] WebSocket connections work

---

## Scaling

### Horizontal Scaling
```bash
heroku ps:scale web=2
```

### Database Scaling
Upgrade to larger PostgreSQL plan when needed.

### Redis Scaling
Upgrade Redis plan for more connections.

---

## Monitoring

### Heroku Logs
```bash
heroku logs --tail
```

### Application Metrics
Use Heroku's built-in metrics or add New Relic addon.

### Error Tracking
Consider adding Sentry for error tracking:
```bash
heroku addons:create sentry
```
