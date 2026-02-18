"""
Admin Configuration for Categories App
"""
from django.contrib import admin
from .models import Category, CategoryStats

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    """Category admin interface."""
    
    list_display = ['id', 'name', 'color', 'icon', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'description']
    
    fieldsets = (
        ('Category Information', {
            'fields': ('id', 'name', 'description')
        }),
        ('Display', {
            'fields': ('color', 'icon')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def has_add_permission(self, request):
        """Only allow the 7 predefined categories."""
        return Category.objects.count() < 7
    
    def has_delete_permission(self, request, obj=None):
        """Prevent deletion of categories."""
        return False


@admin.register(CategoryStats)
class CategoryStatsAdmin(admin.ModelAdmin):
    """Category Stats admin interface."""
    
    list_display = [
        'user', 'category', 'total_tasks', 'completed_tasks',
        'completion_rate', 'total_points_earned'
    ]
    list_filter = ['category', 'last_updated']
    search_fields = ['user__email', 'category__name']
    
    fieldsets = (
        ('User & Category', {
            'fields': ('user', 'category')
        }),
        ('Task Statistics', {
            'fields': (
                'total_tasks', 'completed_tasks', 'pending_tasks', 'overdue_tasks',
                'completion_rate', 'on_time_completion_rate'
            )
        }),
        ('Time Tracking', {
            'fields': (
                'total_time_spent', 'average_completion_time'
            )
        }),
        ('Gamification & Timestamps', {
            'fields': (
                'total_points_earned', 'first_task_created',
                'last_task_completed', 'last_updated'
            )
        }),
    )
    
    readonly_fields = [
        'total_tasks', 'completed_tasks', 'pending_tasks', 'overdue_tasks',
        'completion_rate', 'on_time_completion_rate', 'first_task_created',
        'last_task_completed', 'last_updated'
    ]
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'category')