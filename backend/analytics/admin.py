"""
Admin Configuration for Analytics App
"""
from django.contrib import admin
from .models import UserAnalytics, TaskAnalytics, ProductivityInsight, WeeklyReport

@admin.register(UserAnalytics)
class UserAnalyticsAdmin(admin.ModelAdmin):
    """User Analytics admin interface."""
    
    list_display = [
        'user', 'productivity_score', 'efficiency_rating',
        'completion_rate_30d', 'current_streak_days', 'last_calculated'
    ]
    list_filter = ['efficiency_rating', 'last_calculated']
    search_fields = ['user__email', 'user__display_name']
    
    fieldsets = (
        ('User', {
            'fields': ('user',)
        }),
        ('Productivity Metrics', {
            'fields': (
                'productivity_score', 'efficiency_rating',
                'completion_rate_7d', 'completion_rate_30d', 'completion_rate_overall'
            )
        }),
        ('Time Patterns', {
            'fields': (
                'most_productive_hour', 'least_productive_hour',
                'average_task_duration'
            )
        }),
        ('Streaks & Consistency', {
            'fields': (
                'current_streak_days', 'longest_streak_days',
                'consistency_score'
            )
        }),
        ('AI Insights', {
            'fields': (
                'predicted_completion_probability', 'suggested_daily_task_limit',
                'optimal_scheduling_pattern'
            )
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at', 'last_calculated']

@admin.register(TaskAnalytics)
class TaskAnalyticsAdmin(admin.ModelAdmin):
    """Task Analytics admin interface."""
    
    list_display = [
        'user', 'category', 'start_date', 'end_date',
        'total_tasks', 'completion_rate', 'efficiency_score'
    ]
    list_filter = ['category', 'start_date', 'end_date']
    search_fields = ['user__email', 'category__name']
    date_hierarchy = 'start_date'

@admin.register(ProductivityInsight)
class ProductivityInsightAdmin(admin.ModelAdmin):
    """Productivity Insight admin interface."""
    
    list_display = [
        'user', 'insight_type', 'title', 'confidence_score',
        'is_actionable', 'is_read', 'generated_at'
    ]
    list_filter = ['insight_type', 'is_actionable', 'is_read', 'generated_at']
    search_fields = ['user__email', 'title', 'description']
    date_hierarchy = 'generated_at'

@admin.register(WeeklyReport)
class WeeklyReportAdmin(admin.ModelAdmin):
    """Weekly Report admin interface."""
    
    list_display = [
        'user', 'week_start', 'week_end', 'total_tasks',
        'completion_rate', 'points_earned', 'is_sent'
    ]
    list_filter = ['week_start', 'is_sent', 'generated_at']
    search_fields = ['user__email']
    date_hierarchy = 'week_start'