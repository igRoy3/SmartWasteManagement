from django.urls import path
from .views import (
    CollectionTaskListCreateView,
    CollectionTaskDetailView,
    MyTasksView
)

urlpatterns = [
    path('', CollectionTaskListCreateView.as_view(), name='task-list-create'),
    path('<int:pk>/', CollectionTaskDetailView.as_view(), name='task-detail'),
    path('my-tasks/', MyTasksView.as_view(), name='my-tasks'),
]
