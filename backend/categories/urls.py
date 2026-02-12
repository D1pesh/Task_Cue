"""
URL Configuration for Categories App
"""
from django.urls import path
from .views import (
    CategoryListView, category_stats, category_analytics,
    admin_category_stats, health_check
)

app_name = 'categories'

urlpatterns = [
    # Category endpoints
    path('', CategoryListView.as_view(), name='category-list'),
    path('stats/', category_stats, name='category-stats'),
    path('analytics/', category_analytics, name='category-analytics'),
    
    # Admin endpoints
    path('admin/stats/', admin_category_stats, name='admin-category-stats'),
    
    # Health check
    path('health/', health_check, name='health-check'),
]