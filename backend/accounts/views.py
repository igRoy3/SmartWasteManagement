from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth import update_session_auth_hash
from .models import User
from .serializers import (
    UserSerializer, 
    UserRegistrationSerializer, 
    UserUpdateSerializer,
    ChangePasswordSerializer
)


class RegisterView(generics.CreateAPIView):
    """User registration endpoint."""
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = UserRegistrationSerializer


class UserProfileView(generics.RetrieveUpdateAPIView):
    """Get and update user profile."""
    serializer_class = UserSerializer
    permission_classes = (permissions.IsAuthenticated,)
    
    def get_object(self):
        return self.request.user


class UserUpdateView(generics.UpdateAPIView):
    """Update user profile details."""
    serializer_class = UserUpdateSerializer
    permission_classes = (permissions.IsAuthenticated,)
    
    def get_object(self):
        return self.request.user


class ChangePasswordView(APIView):
    """Change user password."""
    permission_classes = (permissions.IsAuthenticated,)
    
    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            user = request.user
            if not user.check_password(serializer.data.get('old_password')):
                return Response(
                    {'old_password': 'Wrong password.'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            user.set_password(serializer.data.get('new_password'))
            user.save()
            update_session_auth_hash(request, user)
            return Response({'message': 'Password updated successfully.'}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserListView(generics.ListAPIView):
    """List all users (Admin only)."""
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = (permissions.IsAuthenticated,)
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return User.objects.all()
        return User.objects.filter(id=user.id)
