from rest_framework import generics, status, permissions, filters
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate, get_user_model
from django.db.models import Count, Q

from .serializers import (
    UserSerializer,
    UserRegistrationSerializer,
    LoginSerializer,
    ChangePasswordSerializer,
    CollectorDetailSerializer,
)

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    """API view for user registration."""
    
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [permissions.AllowAny]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        }, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    """API view for user login with JWT."""
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = authenticate(
            username=serializer.validated_data['username'],
            password=serializer.validated_data['password']
        )
        
        if user:
            if not user.is_active:
                return Response(
                    {'error': 'Account is disabled'},
                    status=status.HTTP_403_FORBIDDEN
                )
            refresh = RefreshToken.for_user(user)
            return Response({
                'user': UserSerializer(user).data,
                'tokens': {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                }
            })
        return Response(
            {'error': 'Invalid credentials'},
            status=status.HTTP_401_UNAUTHORIZED
        )


class LogoutView(APIView):
    """API view for user logout."""
    
    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if refresh_token:
                token = RefreshToken(refresh_token)
                token.blacklist()
        except Exception:
            pass
        return Response({'message': 'Successfully logged out'})


class ProfileView(generics.RetrieveUpdateAPIView):
    """API view for user profile."""
    
    serializer_class = UserSerializer
    
    def get_object(self):
        return self.request.user


class ChangePasswordView(APIView):
    """API view for changing password."""
    
    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = request.user
        if not user.check_password(serializer.validated_data['old_password']):
            return Response(
                {'error': 'Wrong password'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user.set_password(serializer.validated_data['new_password'])
        user.save()
        return Response({'message': 'Password updated successfully'})


class CollectorListView(generics.ListAPIView):
    """API view to list all collectors (for admin use)."""
    
    serializer_class = CollectorDetailSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['username', 'first_name', 'last_name', 'email']
    ordering_fields = ['created_at', 'username']
    
    def get_queryset(self):
        return User.objects.filter(role='collector').annotate(
            total_tasks=Count('assigned_tasks'),
            completed_tasks=Count('assigned_tasks', filter=Q(assigned_tasks__status='completed')),
            pending_tasks=Count('assigned_tasks', filter=Q(assigned_tasks__status__in=['assigned', 'in_progress']))
        )


class CollectorDetailView(generics.RetrieveUpdateAPIView):
    """API view to get/update collector details."""
    
    serializer_class = CollectorDetailSerializer
    
    def get_queryset(self):
        return User.objects.filter(role='collector').annotate(
            total_tasks=Count('assigned_tasks'),
            completed_tasks=Count('assigned_tasks', filter=Q(assigned_tasks__status='completed')),
            pending_tasks=Count('assigned_tasks', filter=Q(assigned_tasks__status__in=['assigned', 'in_progress']))
        )


class CollectorToggleStatusView(APIView):
    """API view to enable/disable collector accounts."""
    
    def post(self, request, pk):
        try:
            collector = User.objects.get(pk=pk, role='collector')
        except User.DoesNotExist:
            return Response(
                {'error': 'Collector not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        collector.is_active = not collector.is_active
        collector.save()
        
        return Response({
            'message': f"Collector {'enabled' if collector.is_active else 'disabled'} successfully",
            'is_active': collector.is_active
        })


class AdminUserListView(generics.ListAPIView):
    """API view to list all users with statistics."""
    
    serializer_class = UserSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['username', 'first_name', 'last_name', 'email']
    ordering_fields = ['created_at', 'username', 'role']
    
    def get_queryset(self):
        queryset = User.objects.all()
        role = self.request.query_params.get('role')
        if role:
            queryset = queryset.filter(role=role)
        return queryset


class RegisterFCMTokenView(APIView):
    """API view to register/update FCM token for push notifications."""
    
    def post(self, request):
        token = request.data.get('fcm_token')
        if not token:
            return Response(
                {'error': 'FCM token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user = request.user
        user.fcm_token = token
        user.save(update_fields=['fcm_token'])
        
        return Response({'message': 'FCM token registered successfully'})
    
    def delete(self, request):
        """Remove FCM token (e.g., on logout)."""
        user = request.user
        user.fcm_token = None
        user.save(update_fields=['fcm_token'])
        
        return Response({'message': 'FCM token removed successfully'})

