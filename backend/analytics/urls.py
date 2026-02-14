"""
URL Configuration for Analytics App
"""
from django.urls import path
from .views import (
    user_analytics, weekly_report, productivity_insights,
    health_check
)

app_name = 'analytics'

urlpatterns = [
    # Analytics endpoints
    path('user/', user_analytics, name='user-analytics'),
    path('weekly-report/', weekly_report, name='weekly-report'),
    path('insights/', productivity_insights, name='productivity-insights'),
    
    # Health check
    path('health/', health_check, name='health-check'),
]