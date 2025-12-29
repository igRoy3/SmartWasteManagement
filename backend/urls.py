"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response


@api_view(['GET'])
@permission_classes([AllowAny])
def api_root(request):
    """API Root - Shows available endpoints"""
    return Response({
        'message': 'Welcome to Smart Waste Management API',
        'version': '1.0',
        'endpoints': {
            'auth': {
                'register': '/api/auth/register/',
                'login': '/api/auth/login/',
                'logout': '/api/auth/logout/',
                'profile': '/api/auth/profile/',
                'change_password': '/api/auth/change-password/',
                'collectors': '/api/auth/collectors/',
            },
            'citizen': {
                'reports': '/api/reports/citizen/reports/',
                'report_detail': '/api/reports/citizen/reports/<id>/',
            },
            'collector': {
                'tasks': '/api/reports/collector/tasks/',
                'task_detail': '/api/reports/collector/tasks/<id>/',
                'update_status': '/api/reports/collector/tasks/<id>/update-status/',
            },
            'admin': {
                'reports': '/api/reports/admin/reports/',
                'report_detail': '/api/reports/admin/reports/<id>/',
                'assign_collector': '/api/reports/admin/reports/<id>/assign/',
                'reject_report': '/api/reports/admin/reports/<id>/reject/',
                'dashboard': '/api/reports/admin/dashboard/',
            },
            'django_admin': '/admin/',
        }
    })


urlpatterns = [
    path('', api_root, name='api-root'),
    path('admin/', admin.site.urls),
    path('api/auth/', include('accounts.urls')),
    path('api/reports/', include('reports.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
