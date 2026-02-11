"""
Users Models for TaskCue Backend
Handles user authentication, profiles, and session management
"""
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone
from django.core.validators import EmailValidator
import uuid


class CustomUser(AbstractUser):
    """Extended User model with Firebase integration and role management."""
    
    ROLE_CHOICES = [
        ('user', 'Regular User'),
        ('admin', 'Administrator'),
        ('moderator', 'Moderator'),
    ]
    
    # Firebase Integration
    firebase_uid = models.CharField(max_length=256, unique=True, null=True, blank=True)
    
    # User Information
    email = models.EmailField(unique=True, validators=[EmailValidator()])
    display_name = models.CharField(max_length=100, blank=True)
    phone_number = models.CharField(max_length=20, blank=True)
    
    # Role and Permissions
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='user')
    is_verified = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_active = models.DateTimeField(default=timezone.now)
    
    # Account Status
    is_premium = models.BooleanField(default=False)
    premium_expires_at = models.DateTimeField(null=True, blank=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']
    
    class Meta:
        db_table = 'users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.email} ({self.get_role_display()})"
    
    @property
    def full_name(self):
        """Return display name or email if display name is empty."""
        return self.display_name or self.email.split('@')[0]
    
    @property
    def is_admin_user(self):
        """Check if user has admin privileges."""
        return self.role in ['admin', 'moderator']
    
    def update_last_active(self):
        """Update last active timestamp."""
        self.last_active = timezone.now()
        self.save(update_fields=['last_active'])


class UserProfile(models.Model):
    """Extended user profile information."""
    
    TIMEZONE_CHOICES = [
        ('UTC', 'UTC'),
        ('US/Eastern', 'Eastern Time'),
        ('US/Central', 'Central Time'),
        ('US/Mountain', 'Mountain Time'),
        ('US/Pacific', 'Pacific Time'),
        ('Europe/London', 'London Time'),
        ('Europe/Berlin', 'Berlin Time'),
        ('Asia/Tokyo', 'Tokyo Time'),
        ('Asia/Shanghai', 'Shanghai Time'),
        ('Australia/Sydney', 'Sydney Time'),
    ]
    
    LANGUAGE_CHOICES = [
        ('en', 'English'),
        ('es', 'Spanish'),
        ('fr', 'French'),
        ('de', 'German'),
        ('ja', 'Japanese'),
        ('zh', 'Chinese'),
    ]
    
    THEME_CHOICES = [
        ('light', 'Light Theme'),
        ('dark', 'Dark Theme'),
        ('auto', 'Auto (System)'),
    ]
    
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='profile')
    
    # Profile Settings
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    bio = models.TextField(max_length=500, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    
    # App Preferences
    timezone = models.CharField(max_length=50, choices=TIMEZONE_CHOICES, default='UTC')
    language = models.CharField(max_length=10, choices=LANGUAGE_CHOICES, default='en')
    theme = models.CharField(max_length=20, choices=THEME_CHOICES, default='light')
    
    # Notification Preferences
    notifications_enabled = models.BooleanField(default=True)
    email_notifications = models.BooleanField(default=True)
    push_notifications = models.BooleanField(default=True)
    task_reminders = models.BooleanField(default=True)
    daily_summary = models.BooleanField(default=False)
    weekly_report = models.BooleanField(default=False)
    
    # Progress Tracking
    onboarding_completed = models.BooleanField(default=False)
    tutorial_completed = models.BooleanField(default=False)
    
    # Privacy Settings
    profile_public = models.BooleanField(default=False)
    show_in_leaderboard = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'user_profiles'
        verbose_name = 'User Profile'
        verbose_name_plural = 'User Profiles'
    
    def __str__(self):
        return f"Profile for {self.user.email}"


class UserSession(models.Model):
    """Track user sessions for security and analytics."""
    
    PLATFORM_CHOICES = [
        ('android', 'Android'),
        ('ios', 'iOS'),
        ('web', 'Web Browser'),
        ('desktop', 'Desktop App'),
    ]
    
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='sessions')
    session_id = models.UUIDField(default=uuid.uuid4, unique=True)
    
    # Session Details
    platform = models.CharField(max_length=20, choices=PLATFORM_CHOICES, default='web')
    device_info = models.TextField(blank=True)  # JSON string with device details
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    # Location (optional)
    country = models.CharField(max_length=100, blank=True)
    city = models.CharField(max_length=100, blank=True)
    
    # Session Lifecycle
    started_at = models.DateTimeField(auto_now_add=True)
    last_activity = models.DateTimeField(auto_now=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        db_table = 'user_sessions'
        verbose_name = 'User Session'
        verbose_name_plural = 'User Sessions'
        ordering = ['-started_at']
    
    def __str__(self):
        return f"Session {self.session_id} - {self.user.email}"
    
    @property
    def duration(self):
        """Calculate session duration."""
        end_time = self.ended_at or timezone.now()
        return end_time - self.started_at
    
    def end_session(self):
        """End the session."""
        self.ended_at = timezone.now()
        self.is_active = False
        self.save()


class UserActivity(models.Model):
    """Track user activity for analytics and insights."""
    
    ACTIVITY_CHOICES = [
        ('login', 'User Login'),
        ('logout', 'User Logout'),
        ('task_created', 'Task Created'),
        ('task_completed', 'Task Completed'),
        ('task_deleted', 'Task Deleted'),
        ('category_viewed', 'Category Viewed'),
        ('analytics_viewed', 'Analytics Viewed'),
        ('profile_updated', 'Profile Updated'),
        ('achievement_unlocked', 'Achievement Unlocked'),
        ('feature_used', 'Feature Used'),
    ]
    
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='activities')
    session = models.ForeignKey(UserSession, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Activity Details
    activity_type = models.CharField(max_length=50, choices=ACTIVITY_CHOICES)
    activity_data = models.JSONField(default=dict, blank=True)  # Additional activity details
    
    # Context
    timestamp = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    class Meta:
        db_table = 'user_activities'
        verbose_name = 'User Activity'
        verbose_name_plural = 'User Activities'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['user', 'activity_type']),
            models.Index(fields=['timestamp']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.get_activity_type_display()} at {self.timestamp}"