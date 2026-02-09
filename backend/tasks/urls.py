"""
URL Configuration for Tasks App
"""
from django.urls import path
from .views import (
    TaskListCreateView, TaskDetailView,
    complete_task, task_stats, health_check
)

app_name = 'tasks'

urlpatterns = [
    # Task CRUD endpoints
    path('', TaskListCreateView.as_view(), name='task-list-create'),
    path('<uuid:pk>/', TaskDetailView.as_view(), name='task-detail'),
    
    # Task actions
    path('<uuid:task_id>/complete/', complete_task, name='complete-task'),
    
    # Statistics
    path('stats/', task_stats, name='task-stats'),
    
    # Health check
    path('health/', health_check, name='health-check'),
]