"""
Category Serializers for TaskCue API
"""
from rest_framework import serializers
from .models import Category, CategoryStats

class CategorySerializer(serializers.ModelSerializer):
    """Serializer for category data."""
    
    class Meta:
        model = Category
        fields = [
            'id', 'name', 'color', 'icon', 'description',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CategoryStatsSerializer(serializers.ModelSerializer):
    """Serializer for category statistics."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    productivity_score = serializers.SerializerMethodField(read_only=True)
    
    class Meta:
        model = CategoryStats
        fields = [
            'category', 'category_name', 'total_tasks', 'completed_tasks',
            'pending_tasks', 'overdue_tasks', 'completion_rate',
            'on_time_completion_rate', 'total_points_earned',
            'productivity_score', 'total_time_spent', 'average_completion_time',
            'first_task_created', 'last_task_completed', 'last_updated'
        ]
        read_only_fields = [
            'total_tasks', 'completed_tasks', 'pending_tasks', 'overdue_tasks',
            'completion_rate', 'on_time_completion_rate', 'productivity_score',
            'first_task_created', 'last_task_completed', 'last_updated'
        ]
    
    def get_productivity_score(self, obj):
        """Calculate productivity score from model property."""
        return obj.productivity_score