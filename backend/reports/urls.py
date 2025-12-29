from django.urls import path
from .views import (
    GarbageReportListCreateView,
    GarbageReportDetailView,
    MyReportsView,
    ReportCommentCreateView,
    ReportCommentListView
)

urlpatterns = [
    path('', GarbageReportListCreateView.as_view(), name='report-list-create'),
    path('<int:pk>/', GarbageReportDetailView.as_view(), name='report-detail'),
    path('my-reports/', MyReportsView.as_view(), name='my-reports'),
    path('comments/', ReportCommentCreateView.as_view(), name='comment-create'),
    path('<int:report_id>/comments/', ReportCommentListView.as_view(), name='comment-list'),
]
