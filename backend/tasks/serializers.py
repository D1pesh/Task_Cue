"""
Task Serializers for TaskCue API
"""
from rest_framework import serializers
from .models import Task, TaskNote, TaskAttachment, TaskHistory
from categories.models import Category

class TaskSerializer(serializers.ModelSerializer):
    """Serializer for task data."""
    category_name = serializers.CharField(source='category.name', read_only=True)
    is_overdue = serializers.ReadOnlyField()
    time_until_deadline = serializers.ReadOnlyField()
    
    class Meta:
        model = Task
        fields = [
            'id', 'title', 'description', 'category', 'category_name',
            'scheduled_time', 'deadline_time', 'priority', 'status',
            'is_completed', 'estimated_duration', 'actual_duration',
            'points_earned', 'bonus_points', 'is_overdue', 'time_until_deadline',
            'created_at', 'updated_at', 'completed_at'
        ]
        read_only_fields = ['id', 'points_earned', 'bonus_points', 'created_at', 'updated_at']

class TaskCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating tasks."""
    
    class Meta:
        model = Task
        fields = [
            'title', 'description', 'category', 'scheduled_time',
            'deadline_time', 'priority', 'estimated_duration'
        ]
    
    def validate(self, data):
        if data.get('scheduled_time') and data.get('deadline_time'):
            if data['scheduled_time'] > data['deadline_time']:
                raise serializers.ValidationError("Scheduled time cannot be after deadline time")
        return data

class TaskNoteSerializer(serializers.ModelSerializer):
    """Serializer for task notes."""
    
    class Meta:
        model = TaskNote
        fields = ['id', 'content', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']