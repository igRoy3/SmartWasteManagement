from rest_framework import generics, permissions, status, filters
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from .models import CollectionTask
from .serializers import (
    CollectionTaskSerializer,
    CollectionTaskCreateSerializer,
    CollectionTaskUpdateSerializer
)


class IsAdminUser(permissions.BasePermission):
    """Permission class for admin users only."""
    
    def has_permission(self, request, view):
        return request.user and request.user.role == 'admin'


class IsCollectorUser(permissions.BasePermission):
    """Permission class for collector users."""
    
    def has_permission(self, request, view):
        return request.user and request.user.role == 'collector'


class CollectionTaskListCreateView(generics.ListCreateAPIView):
    """List all tasks or create a new one (Admin only)."""
    queryset = CollectionTask.objects.all()
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'priority', 'collector']
    search_fields = ['report__title', 'notes', 'collector__username']
    ordering_fields = ['assigned_at', 'priority']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return CollectionTaskCreateSerializer
        return CollectionTaskSerializer
    
    def get_permissions(self):
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated(), IsAdminUser()]
        return [permissions.IsAuthenticated()]
    
    def perform_create(self, serializer):
        task = serializer.save(assigned_by=self.request.user)
        # Update report status to assigned
        task.report.status = 'assigned'
        task.report.save()


class CollectionTaskDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update or delete a collection task."""
    queryset = CollectionTask.objects.all()
    permission_classes = (permissions.IsAuthenticated,)
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return CollectionTaskUpdateSerializer
        return CollectionTaskSerializer
    
    def get_permissions(self):
        if self.request.method == 'DELETE':
            return [permissions.IsAuthenticated(), IsAdminUser()]
        return [permissions.IsAuthenticated()]


class MyTasksView(generics.ListAPIView):
    """List tasks assigned to the current collector."""
    serializer_class = CollectionTaskSerializer
    permission_classes = (permissions.IsAuthenticated, IsCollectorUser)
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['status', 'priority']
    ordering_fields = ['assigned_at', 'priority']
    
    def get_queryset(self):
        return CollectionTask.objects.filter(collector=self.request.user)
