"""
Admin Configuration for Users App
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from .models import CustomUser, UserProfile, UserSession, UserActivity


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    """Custom User admin interface."""
    
    list_display = [
        'email', 'display_name', 'role', 'is_verified', 'is_premium',
        'is_active', 'created_at', 'last_active'
    ]
    list_filter = ['role', 'is_verified', 'is_premium', 'is_active', 'created_at']
    search_fields = ['email', 'display_name', 'firebase_uid']
    ordering = ['-created_at']
    
    fieldsets = (
        (None, {'fields': ('username', 'password')}),
        ('Personal info', {
            'fields': ('email', 'display_name', 'phone_number', 'firebase_uid')
        }),
        ('Permissions', {
            'fields': ('role', 'is_active', 'is_staff', 'is_superuser', 'is_verified')
        }),
        ('Premium', {
            'fields': ('is_premium', 'premium_expires_at')
        }),
        ('Important dates', {
            'fields': ('last_login', 'created_at', 'last_active')
        }),
    )
    
    readonly_fields = ['created_at', 'last_active']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('profile')


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    """User Profile admin interface."""
    
    list_display = [
        'user', 'timezone', 'language', 'theme',
        'notifications_enabled', 'onboarding_completed'
    ]
    list_filter = [
        'timezone', 'language', 'theme', 'notifications_enabled',
        'onboarding_completed', 'tutorial_completed'
    ]
    search_fields = ['user__email', 'user__display_name']
    
    fieldsets = (
        ('User', {'fields': ('user',)}),
        ('Profile Information', {
            'fields': ('avatar', 'bio', 'date_of_birth')
        }),
        ('App Preferences', {
            'fields': ('timezone', 'language', 'theme')
        }),
        ('Notification Settings', {
            'fields': (
                'notifications_enabled', 'email_notifications',
                'push_notifications', 'task_reminders',
                'daily_summary', 'weekly_report'
            )
        }),
        ('Progress', {
            'fields': ('onboarding_completed', 'tutorial_completed')
        }),
        ('Privacy', {
            'fields': ('profile_public', 'show_in_leaderboard')
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']


@admin.register(UserSession)
class UserSessionAdmin(admin.ModelAdmin):
    """User Session admin interface."""
    
    list_display = [
        'user', 'platform', 'ip_address', 'country',
        'is_active', 'started_at', 'duration_display'
    ]
    list_filter = ['platform', 'is_active', 'started_at', 'country']
    search_fields = ['user__email', 'ip_address', 'session_id']
    
    fieldsets = (
        ('Session Info', {
            'fields': ('user', 'session_id', 'platform', 'device_info')
        }),
        ('Location & Access', {
            'fields': ('ip_address', 'user_agent', 'country', 'city')
        }),
        ('Timeline', {
            'fields': ('started_at', 'last_activity', 'ended_at', 'is_active')
        }),
    )
    
    readonly_fields = ['session_id', 'started_at', 'duration']
    
    def duration_display(self, obj):
        """Display session duration."""
        duration = obj.duration
        if duration:
            total_seconds = int(duration.total_seconds())
            hours = total_seconds // 3600
            minutes = (total_seconds % 3600) // 60
            return f"{hours}h {minutes}m"
        return "-"
    
    duration_display.short_description = "Duration"


@admin.register(UserActivity)
class UserActivityAdmin(admin.ModelAdmin):
    """User Activity admin interface."""
    
    list_display = [
        'user', 'activity_type', 'timestamp', 'ip_address'
    ]
    list_filter = ['activity_type', 'timestamp']
    search_fields = ['user__email', 'activity_type']
    date_hierarchy = 'timestamp'
    
    fieldsets = (
        ('Activity Info', {
            'fields': ('user', 'session', 'activity_type', 'activity_data')
        }),
        ('Context', {
            'fields': ('timestamp', 'ip_address', 'user_agent')
        }),
    )
    
    readonly_fields = ['timestamp']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'session')