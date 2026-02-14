"""
AI Insights module for TaskCue Analytics
Provides AI-powered productivity calculations and insights
"""
import logging
from datetime import datetime, timedelta
from django.utils import timezone
from django.db import models

logger = logging.getLogger(__name__)

class ProductivityCalculator:
    """Calculate productivity scores using AI insights."""
    
    def __init__(self, user):
        self.user = user
    
    def calculate_score(self) -> float:
        """
        Calculate productivity score for user.
        Returns a score between 0-100.
        """
        try:
            # Import here to avoid circular imports
            from tasks.models import Task
            
            # Simple calculation based on completion rates and consistency
            # In a real implementation, this would use more sophisticated ML models
            
            # Get user tasks from last 30 days
            thirty_days_ago = timezone.now() - timedelta(days=30)
            recent_tasks = Task.objects.filter(
                user=self.user,
                created_at__gte=thirty_days_ago
            )
            
            if not recent_tasks.exists():
                return 0.0
            
            # Basic metrics
            total_tasks = recent_tasks.count()
            completed_tasks = recent_tasks.filter(is_completed=True).count()
            completion_rate = (completed_tasks / total_tasks) * 100 if total_tasks > 0 else 0
            
            # On-time completion rate
            on_time_tasks = recent_tasks.filter(
                is_completed=True,
                completed_at__lte=models.F('deadline_time')
            ).count()
            on_time_rate = (on_time_tasks / completed_tasks) * 100 if completed_tasks > 0 else 0
            
            # Consistency score (tasks completed regularly)
            days_with_tasks = recent_tasks.values('completed_at__date').distinct().count()
            consistency = min((days_with_tasks / 30) * 100, 100)
            
            # Weighted average
            productivity_score = (
                completion_rate * 0.4 +
                on_time_rate * 0.3 +
                consistency * 0.3
            )
            
            return min(productivity_score, 100.0)
            
        except Exception as e:
            logger.error(f"Error calculating productivity score: {e}")
            return 50.0  # Default to average score
    
    def generate_insights(self) -> list:
        """Generate AI insights for the user."""
        insights = []
        
        try:
            from tasks.models import Task
            
            # Simple insights based on patterns
            recent_tasks = Task.objects.filter(
                user=self.user,
                created_at__gte=timezone.now() - timedelta(days=7)
            )
            
            if recent_tasks.filter(is_completed=True).count() == 0:
                insights.append({
                    'type': 'warning',
                    'title': 'Low Activity',
                    'description': 'You haven\'t completed any tasks this week. Try setting smaller, achievable goals.',
                    'confidence': 0.8
                })
            
            overdue_count = recent_tasks.filter(
                deadline_time__lt=timezone.now(),
                is_completed=False
            ).count()
            
            if overdue_count > 3:
                insights.append({
                    'type': 'recommendation',
                    'title': 'Time Management',
                    'description': f'You have {overdue_count} overdue tasks. Consider breaking large tasks into smaller ones.',
                    'confidence': 0.7
                })
            
            return insights
            
        except Exception as e:
            logger.error(f"Error generating insights: {e}")
            return []