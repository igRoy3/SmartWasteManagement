from django.urls import path
from .views import (
    # Citizen views
    CitizenReportListCreateView,
    CitizenReportDetailView,
    # Collector views
    CollectorTaskListView,
    CollectorTaskDetailView,
    CollectorUpdateStatusView,
    # Admin views
    AdminReportListView,
    AdminReportDetailView,
    AdminAssignCollectorView,
    AdminRejectReportView,
    AdminDashboardStatsView,
    AdminMapDataView,
    AdminReportAnalyticsView,
)

urlpatterns = [
    # Citizen endpoints
    path('citizen/reports/', CitizenReportListCreateView.as_view(), name='citizen-reports'),
    path('citizen/reports/<int:pk>/', CitizenReportDetailView.as_view(), name='citizen-report-detail'),
    
    # Collector endpoints
    path('collector/tasks/', CollectorTaskListView.as_view(), name='collector-tasks'),
    path('collector/tasks/<int:pk>/', CollectorTaskDetailView.as_view(), name='collector-task-detail'),
    path('collector/tasks/<int:pk>/update-status/', CollectorUpdateStatusView.as_view(), name='collector-update-status'),
    
    # Admin endpoints
    path('admin/reports/', AdminReportListView.as_view(), name='admin-reports'),
    path('admin/reports/<int:pk>/', AdminReportDetailView.as_view(), name='admin-report-detail'),
    path('admin/reports/<int:pk>/assign/', AdminAssignCollectorView.as_view(), name='admin-assign-collector'),
    path('admin/reports/<int:pk>/reject/', AdminRejectReportView.as_view(), name='admin-reject-report'),
    path('admin/dashboard/', AdminDashboardStatsView.as_view(), name='admin-dashboard'),
    path('admin/map/', AdminMapDataView.as_view(), name='admin-map'),
    path('admin/analytics/', AdminReportAnalyticsView.as_view(), name='admin-analytics'),
]
