"""
URL Configuration for Users App
"""
from django.urls import path
from .views import (
    CurrentUserView, UpdateProfileView, UserSessionsView,
    LogoutView, VerifyTokenView, DeleteAccountView,
    AdminUsersView, AdminUserDetailView,
    admin_user_stats, health_check
)

app_name = 'users'

urlpatterns = [
    # User profile endpoints
    path('me/', CurrentUserView.as_view(), name='current-user'),
    path('profile/update/', UpdateProfileView.as_view(), name='update-profile'),
    path('sessions/', UserSessionsView.as_view(), name='user-sessions'),
    
    # Authentication endpoints
    path('logout/', LogoutView.as_view(), name='logout'),
    path('verify-token/', VerifyTokenView.as_view(), name='verify-token'),
    path('delete-account/', DeleteAccountView.as_view(), name='delete-account'),
    
    # Admin endpoints
    path('admin/users/', AdminUsersView.as_view(), name='admin-users'),
    path('admin/users/<int:pk>/', AdminUserDetailView.as_view(), name='admin-user-detail'),
    path('admin/stats/', admin_user_stats, name='admin-stats'),
    
    # Health check
    path('health/', health_check, name='health-check'),
]