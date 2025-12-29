# Deployment Guide

## Backend Deployment

### Option 1: Heroku Deployment

1. **Install Heroku CLI:**
   ```bash
   brew install heroku/brew/heroku  # macOS
   # or download from https://devcenter.heroku.com/articles/heroku-cli
   ```

2. **Login to Heroku:**
   ```bash
   heroku login
   ```

3. **Create Heroku app:**
   ```bash
   cd backend
   heroku create smart-waste-backend
   ```

4. **Add PostgreSQL:**
   ```bash
   heroku addons:create heroku-postgresql:hobby-dev
   ```

5. **Set environment variables:**
   ```bash
   heroku config:set SECRET_KEY=your-secret-key
   heroku config:set DEBUG=False
   heroku config:set ALLOWED_HOSTS=smart-waste-backend.herokuapp.com
   ```

6. **Create Procfile:**
   ```
   web: gunicorn smart_waste.wsgi
   ```

7. **Update requirements.txt:**
   ```bash
   pip install gunicorn
   pip freeze > requirements.txt
   ```

8. **Deploy:**
   ```bash
   git push heroku main
   heroku run python manage.py migrate
   heroku run python manage.py createsuperuser
   ```

### Option 2: DigitalOcean Deployment

1. **Create Droplet:**
   - Choose Ubuntu 22.04
   - Select appropriate size
   - Add SSH key

2. **SSH into server:**
   ```bash
   ssh root@your-server-ip
   ```

3. **Install dependencies:**
   ```bash
   apt update
   apt install python3-pip python3-venv nginx
   ```

4. **Clone repository:**
   ```bash
   cd /var/www
   git clone https://github.com/igRoy3/SmartWasteManagement.git
   cd SmartWasteManagement/backend
   ```

5. **Set up virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   pip install gunicorn
   ```

6. **Configure environment:**
   ```bash
   cp .env.example .env
   nano .env  # Edit with your settings
   ```

7. **Run migrations:**
   ```bash
   python manage.py migrate
   python manage.py collectstatic
   python manage.py createsuperuser
   ```

8. **Create systemd service:**
   ```bash
   nano /etc/systemd/system/smartwaste.service
   ```
   
   Content:
   ```ini
   [Unit]
   Description=Smart Waste Django
   After=network.target

   [Service]
   User=www-data
   Group=www-data
   WorkingDirectory=/var/www/SmartWasteManagement/backend
   Environment="PATH=/var/www/SmartWasteManagement/backend/venv/bin"
   ExecStart=/var/www/SmartWasteManagement/backend/venv/bin/gunicorn --workers 3 --bind unix:/var/www/SmartWasteManagement/backend/smartwaste.sock smart_waste.wsgi:application

   [Install]
   WantedBy=multi-user.target
   ```

9. **Configure Nginx:**
   ```bash
   nano /etc/nginx/sites-available/smartwaste
   ```
   
   Content:
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

       location = /favicon.ico { access_log off; log_not_found off; }
       
       location /static/ {
           root /var/www/SmartWasteManagement/backend;
       }
       
       location /media/ {
           root /var/www/SmartWasteManagement/backend;
       }

       location / {
           include proxy_params;
           proxy_pass http://unix:/var/www/SmartWasteManagement/backend/smartwaste.sock;
       }
   }
   ```

10. **Enable and start services:**
    ```bash
    ln -s /etc/nginx/sites-available/smartwaste /etc/nginx/sites-enabled
    systemctl start smartwaste
    systemctl enable smartwaste
    systemctl restart nginx
    ```

### Option 3: AWS EC2 Deployment

Similar to DigitalOcean but:
1. Create EC2 instance
2. Configure security groups (ports 80, 443, 22)
3. Follow DigitalOcean steps 3-10

## Mobile App Deployment

### Android Deployment

1. **Update configuration:**
   - Update API URL in `lib/utils/api_constants.dart`
   - Add proper signing configuration

2. **Create signing key:**
   ```bash
   keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
   ```

3. **Configure signing:**
   Create `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=key
   storeFile=<path-to-key>/key.jks
   ```

4. **Build release APK:**
   ```bash
   flutter build apk --release
   ```

5. **Distribute:**
   - Upload to Google Play Console
   - Or distribute APK directly

### iOS Deployment

1. **Update configuration:**
   - Update API URL
   - Configure signing in Xcode

2. **Build release:**
   ```bash
   flutter build ios --release
   ```

3. **Archive in Xcode:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Product > Archive
   - Upload to App Store Connect

## SSL/HTTPS Configuration

### Using Let's Encrypt (Free)

1. **Install Certbot:**
   ```bash
   apt install certbot python3-certbot-nginx
   ```

2. **Obtain certificate:**
   ```bash
   certbot --nginx -d your-domain.com
   ```

3. **Auto-renewal:**
   ```bash
   certbot renew --dry-run
   ```

## Database Backup

### PostgreSQL Backup

```bash
# Backup
pg_dump dbname > backup.sql

# Restore
psql dbname < backup.sql
```

### Automated Backups

Create cron job:
```bash
crontab -e
```

Add:
```
0 2 * * * pg_dump dbname > /backups/db_$(date +\%Y\%m\%d).sql
```

## Monitoring

### Setup Monitoring

1. **Install monitoring tools:**
   - Sentry for error tracking
   - New Relic for performance
   - Datadog for infrastructure

2. **Add to Django settings:**
   ```python
   import sentry_sdk
   from sentry_sdk.integrations.django import DjangoIntegration

   sentry_sdk.init(
       dsn="your-sentry-dsn",
       integrations=[DjangoIntegration()],
   )
   ```

## Security Checklist

- [ ] Change SECRET_KEY
- [ ] Set DEBUG=False
- [ ] Configure ALLOWED_HOSTS
- [ ] Use HTTPS
- [ ] Set up firewall
- [ ] Regular backups
- [ ] Update dependencies
- [ ] Monitor logs
- [ ] Rate limiting
- [ ] CSRF protection enabled

## Performance Optimization

1. **Enable caching:**
   - Redis for sessions
   - Database query optimization
   - CDN for static files

2. **Scale horizontally:**
   - Load balancer
   - Multiple app servers
   - Database read replicas

3. **Optimize queries:**
   - Use select_related/prefetch_related
   - Add database indexes
   - Query profiling

## Maintenance

### Regular Tasks

1. **Update dependencies:**
   ```bash
   pip list --outdated
   pip install --upgrade package-name
   ```

2. **Database maintenance:**
   ```bash
   python manage.py clearsessions
   ```

3. **Log rotation:**
   Configure logrotate for application logs

4. **Security updates:**
   Keep OS and packages updated

## Rollback Strategy

1. **Keep previous version:**
   ```bash
   git tag v1.0.0
   ```

2. **Quick rollback:**
   ```bash
   git checkout v1.0.0
   systemctl restart smartwaste
   ```

3. **Database rollback:**
   - Keep database backups before migrations
   - Test rollback procedure

## Support

For deployment issues:
- Check logs: `/var/log/nginx/error.log`
- Django logs: Check systemd journal
- Open GitHub issue for help
