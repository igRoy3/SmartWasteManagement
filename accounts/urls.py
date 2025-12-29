from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView,
    LoginView,
    LogoutView,
    ProfileView,
    ChangePasswordView,
    CollectorListView,
    CollectorDetailView,
    CollectorToggleStatusView,
    AdminUserListView,
    RegisterFCMTokenView,
)

urlpatterns = [
    # Auth endpoints
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('fcm-token/', RegisterFCMTokenView.as_view(), name='fcm-token'),
    
    # Collector management (Admin)
    path('collectors/', CollectorListView.as_view(), name='collector-list'),
    path('collectors/<int:pk>/', CollectorDetailView.as_view(), name='collector-detail'),
    path('collectors/<int:pk>/toggle-status/', CollectorToggleStatusView.as_view(), name='collector-toggle-status'),
    
    # User management (Admin)
    path('users/', AdminUserListView.as_view(), name='user-list'),
]
