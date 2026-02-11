"""
User Serializers for TaskCue API
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import UserProfile, UserSession, UserActivity

User = get_user_model()

class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for user profile data."""
    
    class Meta:
        model = UserProfile
        fields = [
            'avatar', 'bio', 'date_of_birth', 'timezone', 'language', 'theme',
            'notifications_enabled', 'email_notifications', 'push_notifications',
            'task_reminders', 'daily_summary', 'weekly_report',
            'onboarding_completed', 'tutorial_completed',
            'profile_public', 'show_in_leaderboard'
        ]


class UserSerializer(serializers.ModelSerializer):
    """Serializer for user data."""
    profile = UserProfileSerializer(read_only=True)
    full_name = serializers.ReadOnlyField()
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'username', 'display_name', 'full_name',
            'phone_number', 'role', 'is_verified', 'is_premium',
            'created_at', 'updated_at', 'last_active', 'profile'
        ]
        read_only_fields = ['id', 'role', 'is_verified', 'is_premium', 'created_at']


class UpdateProfileSerializer(serializers.ModelSerializer):
    """Serializer for updating user profile."""
    profile = UserProfileSerializer()
    
    class Meta:
        model = User
        fields = ['display_name', 'phone_number', 'profile']
    
    def update(self, instance, validated_data):
        profile_data = validated_data.pop('profile', {})
        
        # Update user fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update profile fields
        if profile_data:
            profile = instance.profile
            for attr, value in profile_data.items():
                setattr(profile, attr, value)
            profile.save()
        
        return instance


class UserSessionSerializer(serializers.ModelSerializer):
    """Serializer for user sessions."""
    duration = serializers.ReadOnlyField()
    
    class Meta:
        model = UserSession
        fields = [
            'session_id', 'platform', 'device_info', 'ip_address',
            'country', 'city', 'started_at', 'last_activity',
            'ended_at', 'is_active', 'duration'
        ]
        read_only_fields = ['session_id', 'started_at', 'duration']


class UserActivitySerializer(serializers.ModelSerializer):
    """Serializer for user activities."""
    
    class Meta:
        model = UserActivity
        fields = ['activity_type', 'activity_data', 'timestamp']
        read_only_fields = ['timestamp']


class AdminUserSerializer(serializers.ModelSerializer):
    """Admin serializer with additional fields."""
    profile = UserProfileSerializer(read_only=True)
    session_count = serializers.SerializerMethodField()
    last_activity_count = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'username', 'display_name', 'firebase_uid',
            'role', 'is_verified', 'is_premium', 'is_active', 'is_staff',
            'created_at', 'updated_at', 'last_active', 'premium_expires_at',
            'profile', 'session_count', 'last_activity_count'
        ]
    
    def get_session_count(self, obj):
        return obj.sessions.filter(is_active=True).count()
    
    def get_last_activity_count(self, obj):
        from django.utils import timezone
        from datetime import timedelta
        
        last_24h = timezone.now() - timedelta(hours=24)
        return obj.activities.filter(timestamp__gte=last_24h).count()