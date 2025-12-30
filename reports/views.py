from rest_framework import generics, status, permissions, filters
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.decorators import action
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db import models
from django.db.models import Count, Q
from django.db.models.functions import TruncDate

from .models import GarbageReport, ReportUpdate
from .serializers import (
    GarbageReportSerializer,
    GarbageReportCreateSerializer,
    AssignCollectorSerializer,
    UpdateStatusSerializer,
    ReportUpdateSerializer,
    MapReportSerializer,
)

User = get_user_model()


class IsAdminUser(permissions.BasePermission):
    """Permission check for admin users."""
    
    def has_permission(self, request, view):
        return request.user.role == 'admin'


class IsCollector(permissions.BasePermission):
    """Permission check for collector users."""
    
    def has_permission(self, request, view):
        return request.user.role == 'collector'


class IsCitizen(permissions.BasePermission):
    """Permission check for citizen users."""
    
    def has_permission(self, request, view):
        return request.user.role == 'citizen'


# Citizen Views
class CitizenReportListCreateView(generics.ListCreateAPIView):
    """API view for citizens to list their reports and create new ones."""
    
    permission_classes = [permissions.IsAuthenticated, IsCitizen]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return GarbageReportCreateSerializer
        return GarbageReportSerializer
    
    def get_queryset(self):
        return GarbageReport.objects.filter(reported_by=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(reported_by=self.request.user)


class CitizenReportDetailView(generics.RetrieveAPIView):
    """API view for citizens to view their report details."""
    
    serializer_class = GarbageReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsCitizen]
    
    def get_queryset(self):
        return GarbageReport.objects.filter(reported_by=self.request.user)


# Collector Views
class CollectorTaskListView(generics.ListAPIView):
    """API view for collectors to view their assigned tasks."""
    
    serializer_class = GarbageReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsCollector]
    
    def get_queryset(self):
        return GarbageReport.objects.filter(
            assigned_to=self.request.user
        )


class CollectorTaskDetailView(generics.RetrieveAPIView):
    """API view for collectors to view task details."""
    
    serializer_class = GarbageReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsCollector]
    
    def get_queryset(self):
        return GarbageReport.objects.filter(assigned_to=self.request.user)


class CollectorUpdateStatusView(APIView):
    """API view for collectors to update task status."""
    
    permission_classes = [permissions.IsAuthenticated, IsCollector]
    
    def post(self, request, pk):
        try:
            report = GarbageReport.objects.get(
                pk=pk,
                assigned_to=request.user
            )
        except GarbageReport.DoesNotExist:
            return Response(
                {'error': 'Task not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = UpdateStatusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        new_status = serializer.validated_data['status']
        note = serializer.validated_data.get('note', '')
        
        # Update report status
        report.status = new_status
        if new_status == 'completed':
            report.completed_at = timezone.now()
        report.save()
        
        # Create status update record
        ReportUpdate.objects.create(
            report=report,
            status=new_status,
            note=note,
            updated_by=request.user
        )
        
        return Response(GarbageReportSerializer(report).data)


# Admin Views
class AdminReportListView(generics.ListAPIView):
    """API view for admins to view all reports with filtering."""
    
    serializer_class = GarbageReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description', 'address']
    ordering_fields = ['created_at', 'status', 'waste_type']
    
    def get_queryset(self):
        queryset = GarbageReport.objects.all()
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by waste type
        waste_type = self.request.query_params.get('waste_type')
        if waste_type:
            queryset = queryset.filter(waste_type=waste_type)
        
        # Filter by collector
        collector_id = self.request.query_params.get('collector')
        if collector_id:
            queryset = queryset.filter(assigned_to_id=collector_id)
        
        # Filter by date range
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        if date_from:
            queryset = queryset.filter(created_at__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(created_at__date__lte=date_to)
        
        return queryset


class AdminReportDetailView(generics.RetrieveAPIView):
    """API view for admins to view report details."""
    
    serializer_class = GarbageReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    queryset = GarbageReport.objects.all()


class AdminAssignCollectorView(APIView):
    """API view for admins to assign collectors to reports."""
    
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    
    def post(self, request, pk):
        try:
            report = GarbageReport.objects.get(pk=pk)
        except GarbageReport.DoesNotExist:
            return Response(
                {'error': 'Report not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = AssignCollectorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        collector = User.objects.get(
            id=serializer.validated_data['collector_id']
        )
        
        report.assigned_to = collector
        report.status = 'assigned'
        report.save()
        
        # Create status update record
        ReportUpdate.objects.create(
            report=report,
            status='assigned',
            note=f'Assigned to {collector.username}',
            updated_by=request.user
        )
        
        return Response(GarbageReportSerializer(report).data)


class AdminRejectReportView(APIView):
    """API view for admins to reject reports."""
    
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    
    def post(self, request, pk):
        try:
            report = GarbageReport.objects.get(pk=pk)
        except GarbageReport.DoesNotExist:
            return Response(
                {'error': 'Report not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        note = request.data.get('note', 'Report rejected by admin')
        
        report.status = 'rejected'
        report.save()
        
        ReportUpdate.objects.create(
            report=report,
            status='rejected',
            note=note,
            updated_by=request.user
        )
        
        return Response(GarbageReportSerializer(report).data)


class AdminDashboardStatsView(APIView):
    """API view for admin dashboard statistics."""
    
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    
    def get(self, request):
        total_reports = GarbageReport.objects.count()
        pending_reports = GarbageReport.objects.filter(status='pending').count()
        assigned_reports = GarbageReport.objects.filter(status='assigned').count()
        in_progress_reports = GarbageReport.objects.filter(status='in_progress').count()
        completed_reports = GarbageReport.objects.filter(status='completed').count()
        rejected_reports = GarbageReport.objects.filter(status='rejected').count()
        
        total_collectors = User.objects.filter(role='collector').count()
        total_citizens = User.objects.filter(role='citizen').count()
        
        return Response({
            'reports': {
                'total': total_reports,
                'pending': pending_reports,
                'assigned': assigned_reports,
                'in_progress': in_progress_reports,
                'completed': completed_reports,
                'rejected': rejected_reports
            },
            'users': {
                'collectors': total_collectors,
                'citizens': total_citizens,
                'active_collectors': User.objects.filter(role='collector', is_active=True).count()
            }
        })


class AdminMapDataView(APIView):
    """API view for map data - all reports with location."""
    
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    
    def get(self, request):
        reports = GarbageReport.objects.exclude(
            status='rejected'
        ).select_related('reported_by', 'assigned_to')
        
        serializer = MapReportSerializer(reports, many=True)
        return Response(serializer.data)


class AdminReportAnalyticsView(APIView):
    """API view for detailed analytics."""
    
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    
    def get(self, request):
        from datetime import timedelta
        from django.db.models import Avg, F, ExpressionWrapper, DurationField
        from django.db.models.functions import ExtractHour, ExtractWeekDay
        
        # Reports by waste type
        by_waste_type = GarbageReport.objects.values('waste_type').annotate(
            count=Count('id')
        ).order_by('-count')
        
        # Reports by status
        by_status = GarbageReport.objects.values('status').annotate(
            count=Count('id')
        ).order_by('-count')
        
        # Reports over time (last 30 days)
        thirty_days_ago = timezone.now() - timedelta(days=30)
        daily_reports = GarbageReport.objects.filter(
            created_at__gte=thirty_days_ago
        ).annotate(
            date=TruncDate('created_at')
        ).values('date').annotate(
            count=Count('id')
        ).order_by('date')
        
        # Top collectors by completed tasks
        top_collectors = User.objects.filter(
            role='collector'
        ).annotate(
            completed=Count('assigned_tasks', filter=Q(assigned_tasks__status='completed'))
        ).order_by('-completed')[:5].values('id', 'username', 'first_name', 'last_name', 'completed')
        
        # NEW: Average resolution time (for completed reports)
        completed_reports = GarbageReport.objects.filter(
            status='completed',
            completed_at__isnull=False
        ).annotate(
            resolution_time=ExpressionWrapper(
                F('completed_at') - F('created_at'),
                output_field=DurationField()
            )
        )
        avg_resolution_hours = None
        if completed_reports.exists():
            total_seconds = sum(
                (r.resolution_time.total_seconds() for r in completed_reports), 
                0
            )
            avg_resolution_hours = round(total_seconds / completed_reports.count() / 3600, 1)
        
        # NEW: Reports by hour of day
        hourly_distribution = GarbageReport.objects.annotate(
            hour=ExtractHour('created_at')
        ).values('hour').annotate(
            count=Count('id')
        ).order_by('hour')
        
        # NEW: Reports by day of week (1=Sunday, 7=Saturday in Django)
        weekly_distribution = GarbageReport.objects.annotate(
            weekday=ExtractWeekDay('created_at')
        ).values('weekday').annotate(
            count=Count('id')
        ).order_by('weekday')
        
        # NEW: Completion rate over time (last 30 days)
        completion_trend = []
        for i in range(30):
            date = timezone.now().date() - timedelta(days=29-i)
            total = GarbageReport.objects.filter(created_at__date__lte=date).count()
            completed = GarbageReport.objects.filter(
                status='completed',
                completed_at__date__lte=date
            ).count()
            rate = round((completed / total * 100), 1) if total > 0 else 0
            completion_trend.append({'date': str(date), 'rate': rate})
        
        # NEW: Collector performance metrics
        collector_performance = User.objects.filter(
            role='collector'
        ).annotate(
            total_tasks=Count('assigned_tasks'),
            completed_tasks=Count('assigned_tasks', filter=Q(assigned_tasks__status='completed')),
            pending_tasks=Count('assigned_tasks', filter=Q(assigned_tasks__status__in=['pending', 'assigned', 'in_progress']))
        ).filter(total_tasks__gt=0).values(
            'id', 'username', 'first_name', 'last_name', 
            'total_tasks', 'completed_tasks', 'pending_tasks'
        ).order_by('-completed_tasks')[:10]
        
        # NEW: Recent activity (last 7 days comparison)
        seven_days_ago = timezone.now() - timedelta(days=7)
        fourteen_days_ago = timezone.now() - timedelta(days=14)
        
        recent_reports = GarbageReport.objects.filter(created_at__gte=seven_days_ago).count()
        previous_reports = GarbageReport.objects.filter(
            created_at__gte=fourteen_days_ago,
            created_at__lt=seven_days_ago
        ).count()
        report_trend = ((recent_reports - previous_reports) / previous_reports * 100) if previous_reports > 0 else 0
        
        recent_completed = GarbageReport.objects.filter(
            status='completed',
            completed_at__gte=seven_days_ago
        ).count()
        previous_completed = GarbageReport.objects.filter(
            status='completed',
            completed_at__gte=fourteen_days_ago,
            completed_at__lt=seven_days_ago
        ).count()
        completion_trend_percent = ((recent_completed - previous_completed) / previous_completed * 100) if previous_completed > 0 else 0
        
        return Response({
            'by_waste_type': list(by_waste_type),
            'by_status': list(by_status),
            'daily_reports': list(daily_reports),
            'top_collectors': list(top_collectors),
            # New analytics
            'avg_resolution_hours': avg_resolution_hours,
            'hourly_distribution': list(hourly_distribution),
            'weekly_distribution': list(weekly_distribution),
            'completion_trend': completion_trend,
            'collector_performance': list(collector_performance),
            'trends': {
                'reports': {
                    'current': recent_reports,
                    'previous': previous_reports,
                    'percent_change': round(report_trend, 1)
                },
                'completions': {
                    'current': recent_completed,
                    'previous': previous_completed,
                    'percent_change': round(completion_trend_percent, 1)
                }
            }
        })
