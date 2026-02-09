"""
Admin Configuration for Tasks App
"""
from django.contrib import admin
from .models import Task, TaskNote, TaskAttachment, TaskHistory

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    """Task admin interface."""
    
    list_display = [
        'title', 'user', 'category', 'priority', 'status',
        'scheduled_time', 'deadline_time', 'is_completed', 'created_at'
    ]
    list_filter = [
        'category', 'priority', 'status', 'is_completed',
        'created_at', 'deadline_time'
    ]
    search_fields = ['title', 'description', 'user__email']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Task Information', {
            'fields': ('title', 'description', 'user', 'category')
        }),
        ('Scheduling', {
            'fields': ('scheduled_time', 'deadline_time', 'estimated_duration')
        }),
        ('Status', {
            'fields': ('priority', 'status', 'is_completed')
        }),
        ('Time Tracking', {
            'fields': ('actual_duration', 'started_at', 'completed_at')
        }),
        ('Gamification', {
            'fields': ('points_earned', 'bonus_points')
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at', 'points_earned', 'bonus_points']

@admin.register(TaskNote)
class TaskNoteAdmin(admin.ModelAdmin):
    """Task Note admin interface."""
    
    list_display = ['task', 'user', 'created_at']
    list_filter = ['created_at']
    search_fields = ['task__title', 'user__email', 'content']

@admin.register(TaskHistory)
class TaskHistoryAdmin(admin.ModelAdmin):
    """Task History admin interface."""
    
    list_display = ['task', 'user', 'action', 'timestamp']
    list_filter = ['action', 'timestamp']
    search_fields = ['task__title', 'user__email']
    readonly_fields = ['timestamp']