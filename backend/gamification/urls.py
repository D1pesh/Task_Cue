"""
URL Configuration for Gamification App
"""
from django.urls import path
from .views import (
    user_points, user_achievements, leaderboard, 
    award_points, health_check
)

app_name = 'gamification'

urlpatterns = [
    # Gamification endpoints
    path('points/', user_points, name='user-points'),
    path('achievements/', user_achievements, name='user-achievements'),
    path('leaderboard/', leaderboard, name='leaderboard'),
    path('award-points/', award_points, name='award-points'),
    
    # Health check
    path('health/', health_check, name='health-check'),
]