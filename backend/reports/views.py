from rest_framework import generics, permissions, status, filters
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from .models import GarbageReport, ReportComment
from .serializers import (
    GarbageReportSerializer,
    GarbageReportCreateSerializer,
    GarbageReportUpdateSerializer,
    ReportCommentSerializer
)


class IsAdminOrReadOnly(permissions.BasePermission):
    """Custom permission: only admins can edit."""
    
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user and request.user.role == 'admin'


class GarbageReportListCreateView(generics.ListCreateAPIView):
    """List all reports or create a new one."""
    queryset = GarbageReport.objects.all()
    permission_classes = (permissions.IsAuthenticated,)
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'garbage_type']
    search_fields = ['title', 'description', 'address']
    ordering_fields = ['created_at', 'updated_at']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return GarbageReportCreateSerializer
        return GarbageReportSerializer
    
    def perform_create(self, serializer):
        serializer.save(reporter=self.request.user)


class GarbageReportDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update or delete a garbage report."""
    queryset = GarbageReport.objects.all()
    permission_classes = (permissions.IsAuthenticated,)
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return GarbageReportUpdateSerializer
        return GarbageReportSerializer
    
    def get_permissions(self):
        if self.request.method in ['PUT', 'PATCH', 'DELETE']:
            return [permissions.IsAuthenticated(), IsAdminOrReadOnly()]
        return [permissions.IsAuthenticated()]


class MyReportsView(generics.ListAPIView):
    """List reports created by the current user."""
    serializer_class = GarbageReportSerializer
    permission_classes = (permissions.IsAuthenticated,)
    
    def get_queryset(self):
        return GarbageReport.objects.filter(reporter=self.request.user)


class ReportCommentCreateView(generics.CreateAPIView):
    """Add a comment to a report."""
    serializer_class = ReportCommentSerializer
    permission_classes = (permissions.IsAuthenticated,)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ReportCommentListView(generics.ListAPIView):
    """List comments for a specific report."""
    serializer_class = ReportCommentSerializer
    permission_classes = (permissions.IsAuthenticated,)
    
    def get_queryset(self):
        report_id = self.kwargs.get('report_id')
        return ReportComment.objects.filter(report_id=report_id)
