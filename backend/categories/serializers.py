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
    efficiency_score = serializers.ReadOnlyField()
    
    class Meta:
        model = CategoryStats
        fields = [
            'category', 'category_name', 'total_tasks', 'completed_tasks',
            'completion_rate', 'on_time_completion_rate', 'current_streak',
            'longest_streak', 'total_points_earned', 'efficiency_score',
            'most_productive_hour', 'last_activity'
        ]
        read_only_fields = [
            'total_tasks', 'completed_tasks', 'completion_rate',
            'current_streak', 'longest_streak', 'efficiency_score'
        ]