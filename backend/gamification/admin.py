"""
Admin Configuration for Gamification App
"""
from django.contrib import admin
from .models import UserPoints, Streak, Achievement, UserAchievement, PointsTransaction

@admin.register(UserPoints)
class UserPointsAdmin(admin.ModelAdmin):
    """User Points admin interface."""
    
    list_display = [
        'user', 'total_points', 'current_level', 'points_this_week',
        'points_this_month', 'updated_at'
    ]
    list_filter = ['current_level', 'last_weekly_reset', 'last_monthly_reset']
    search_fields = ['user__email', 'user__display_name']
    
    fieldsets = (
        ('User', {
            'fields': ('user',)
        }),
        ('Points', {
            'fields': (
                'total_points', 'lifetime_points',
                'points_this_week', 'points_this_month'
            )
        }),
        ('Level System', {
            'fields': ('current_level', 'points_to_next_level')
        }),
        ('Reset Tracking', {
            'fields': ('last_weekly_reset', 'last_monthly_reset')
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']

@admin.register(Streak)
class StreakAdmin(admin.ModelAdmin):
    """Streak admin interface."""
    
    list_display = [
        'user', 'streak_type', 'current_count', 'best_count',
        'last_activity_date', 'is_active'
    ]
    list_filter = ['streak_type', 'is_active', 'last_activity_date']
    search_fields = ['user__email', 'streak_type']

@admin.register(Achievement)
class AchievementAdmin(admin.ModelAdmin):
    """Achievement admin interface."""
    
    list_display = [
        'achievement_id', 'name', 'achievement_type', 'difficulty',
        'points_reward', 'is_active'
    ]
    list_filter = ['achievement_type', 'difficulty', 'is_active']
    search_fields = ['name', 'achievement_id', 'description']
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('achievement_id', 'name', 'description', 'achievement_type')
        }),
        ('Display', {
            'fields': ('icon', 'color')
        }),
        ('Difficulty & Rewards', {
            'fields': ('difficulty', 'points_reward')
        }),
        ('Requirements', {
            'fields': ('requirements',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
    )

@admin.register(UserAchievement)
class UserAchievementAdmin(admin.ModelAdmin):
    """User Achievement admin interface."""
    
    list_display = ['user', 'achievement', 'earned_at']
    list_filter = ['earned_at', 'achievement__achievement_type']
    search_fields = ['user__email', 'achievement__name']
    date_hierarchy = 'earned_at'

@admin.register(PointsTransaction)
class PointsTransactionAdmin(admin.ModelAdmin):
    """Points Transaction admin interface."""
    
    list_display = [
        'user', 'points', 'transaction_type', 'reason', 'timestamp'
    ]
    list_filter = ['transaction_type', 'timestamp']
    search_fields = ['user__email', 'reason']
    date_hierarchy = 'timestamp'