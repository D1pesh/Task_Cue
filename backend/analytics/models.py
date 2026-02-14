"""
Analytics Models for TaskCue Backend
Provides AI-powered insights and productivity analytics
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
import json

User = get_user_model()


class UserAnalytics(models.Model):
    """Main analytics model for user productivity insights."""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='analytics')
    
    # Overall productivity metrics
    productivity_score = models.FloatField(default=0.0)  # 0-100
    efficiency_rating = models.CharField(max_length=20, default='average')  # excellent, good, average, poor
    
    # Task completion patterns
    average_daily_tasks = models.FloatField(default=0.0)
    completion_rate_7d = models.FloatField(default=0.0)
    completion_rate_30d = models.FloatField(default=0.0)
    completion_rate_overall = models.FloatField(default=0.0)
    
    # Time management insights
    most_productive_hour = models.IntegerField(null=True, blank=True)  # 0-23
    least_productive_hour = models.IntegerField(null=True, blank=True)  # 0-23
    average_task_duration = models.FloatField(default=0.0)  # in hours
    
    # Streaks and consistency
    current_streak_days = models.PositiveIntegerField(default=0)
    longest_streak_days = models.PositiveIntegerField(default=0)
    consistency_score = models.FloatField(default=0.0)  # 0-100
    
    # Category preferences
    preferred_category_id = models.IntegerField(null=True, blank=True)
    category_distribution = models.JSONField(default=dict)  # {category_id: percentage}
    
    # AI predictions
    predicted_completion_probability = models.FloatField(default=0.5)  # 0-1
    suggested_daily_task_limit = models.PositiveIntegerField(default=5)
    optimal_scheduling_pattern = models.TextField(blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_calculated = models.DateTimeField(default=timezone.now)
    
    class Meta:
        db_table = 'user_analytics'
        verbose_name = 'User Analytics'
        verbose_name_plural = 'User Analytics'
    
    def __str__(self):
        return f"Analytics for {self.user.email}"
    
    def calculate_productivity_score(self):
        """Calculate overall productivity score using AI insights."""
        try:
            from .ai_insights import ProductivityCalculator
            calculator = ProductivityCalculator(self.user)
            self.productivity_score = calculator.calculate_score()
            self.last_calculated = timezone.now()
            self.save()
        except ImportError:
            # Fallback calculation without AI
            self.productivity_score = self.completion_rate_30d * 0.8 + self.consistency_score * 0.2
    
    def update_insights(self):
        """Update all analytics insights for this user."""
        self._update_completion_rates()
        self._update_time_patterns()
        self._update_category_distribution()
        self.calculate_productivity_score()
    
    def _update_completion_rates(self):
        """Update completion rate metrics."""
        from tasks.models import Task
        from datetime import timedelta
        
        now = timezone.now()
        
        # 7-day completion rate
        tasks_7d = Task.objects.filter(
            user=self.user,
            created_at__gte=now - timedelta(days=7)
        )
        if tasks_7d.exists():
            self.completion_rate_7d = tasks_7d.filter(is_completed=True).count() / tasks_7d.count() * 100
        
        # 30-day completion rate
        tasks_30d = Task.objects.filter(
            user=self.user,
            created_at__gte=now - timedelta(days=30)
        )
        if tasks_30d.exists():
            self.completion_rate_30d = tasks_30d.filter(is_completed=True).count() / tasks_30d.count() * 100
        
        # Overall completion rate
        all_tasks = Task.objects.filter(user=self.user)
        if all_tasks.exists():
            self.completion_rate_overall = all_tasks.filter(is_completed=True).count() / all_tasks.count() * 100
    
    def _update_time_patterns(self):
        """Update time-based productivity patterns."""
        from tasks.models import Task
        from django.db.models import Count
        
        # Find most productive hour
        completed_tasks_by_hour = Task.objects.filter(
            user=self.user,
            is_completed=True,
            completed_at__isnull=False
        ).extra(
            select={'hour': 'EXTRACT(hour FROM completed_at)'}
        ).values('hour').annotate(count=Count('id')).order_by('-count')
        
        if completed_tasks_by_hour:
            self.most_productive_hour = completed_tasks_by_hour[0]['hour']
    
    def _update_category_distribution(self):
        """Update category usage distribution."""
        from tasks.models import Task
        from django.db.models import Count
        
        category_counts = Task.objects.filter(user=self.user).values(
            'category_id'
        ).annotate(count=Count('id'))
        
        total_tasks = sum(item['count'] for item in category_counts)
        
        if total_tasks > 0:
            distribution = {}
            for item in category_counts:
                distribution[str(item['category_id'])] = (item['count'] / total_tasks) * 100
            self.category_distribution = distribution


class TaskAnalytics(models.Model):
    """Analytics for individual tasks and patterns."""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='task_analytics')
    category = models.ForeignKey('categories.Category', on_delete=models.CASCADE, related_name='analytics')
    
    # Date range (usually weekly or monthly aggregation)
    start_date = models.DateField()
    end_date = models.DateField()
    
    # Task metrics for this period
    total_tasks = models.PositiveIntegerField(default=0)
    completed_tasks = models.PositiveIntegerField(default=0)
    overdue_tasks = models.PositiveIntegerField(default=0)
    cancelled_tasks = models.PositiveIntegerField(default=0)
    
    # Time metrics
    total_time_spent = models.PositiveIntegerField(default=0)  # in minutes
    average_completion_time = models.FloatField(default=0.0)  # in hours
    
    # Performance metrics
    completion_rate = models.FloatField(default=0.0)
    on_time_rate = models.FloatField(default=0.0)
    efficiency_score = models.FloatField(default=0.0)
    
    # Points and gamification
    points_earned = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'task_analytics'
        verbose_name = 'Task Analytics'
        verbose_name_plural = 'Task Analytics'
        unique_together = ['user', 'category', 'start_date', 'end_date']
        indexes = [
            models.Index(fields=['user', 'start_date', 'end_date']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.category.name} ({self.start_date} to {self.end_date})"


class ProductivityInsight(models.Model):
    """AI-generated productivity insights and recommendations."""
    
    INSIGHT_TYPES = [
        ('trend', 'Productivity Trend'),
        ('pattern', 'Behavioral Pattern'),
        ('recommendation', 'Improvement Recommendation'),
        ('achievement', 'Achievement Unlocked'),
        ('warning', 'Performance Warning'),
        ('prediction', 'Future Prediction'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='insights')
    insight_type = models.CharField(max_length=20, choices=INSIGHT_TYPES)
    
    # Insight content
    title = models.CharField(max_length=255)
    description = models.TextField()
    data_points = models.JSONField(default=dict)  # Supporting data
    confidence_score = models.FloatField(default=0.0)  # 0-1 AI confidence
    
    # Metadata
    category = models.ForeignKey('categories.Category', on_delete=models.CASCADE, null=True, blank=True)
    is_actionable = models.BooleanField(default=False)
    is_read = models.BooleanField(default=False)
    
    # Timestamps
    generated_at = models.DateTimeField(auto_now_add=True)
    valid_until = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'productivity_insights'
        verbose_name = 'Productivity Insight'
        verbose_name_plural = 'Productivity Insights'
        ordering = ['-generated_at']
        indexes = [
            models.Index(fields=['user', 'insight_type']),
            models.Index(fields=['generated_at']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.user.email}"


class WeeklyReport(models.Model):
    """Weekly productivity reports for users."""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='weekly_reports')
    week_start = models.DateField()
    week_end = models.DateField()
    
    # Weekly summary
    total_tasks = models.PositiveIntegerField(default=0)
    completed_tasks = models.PositiveIntegerField(default=0)
    completion_rate = models.FloatField(default=0.0)
    
    # Time tracking
    total_time_logged = models.PositiveIntegerField(default=0)  # in minutes
    most_productive_day = models.CharField(max_length=10, blank=True)  # monday, tuesday, etc.
    
    # Category breakdown
    category_stats = models.JSONField(default=dict)
    
    # Achievements this week
    achievements_unlocked = models.JSONField(default=list)
    points_earned = models.PositiveIntegerField(default=0)
    
    # AI insights
    key_insights = models.JSONField(default=list)
    recommendations = models.JSONField(default=list)
    
    # Report metadata
    generated_at = models.DateTimeField(auto_now_add=True)
    is_sent = models.BooleanField(default=False)
    sent_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'weekly_reports'
        verbose_name = 'Weekly Report'
        verbose_name_plural = 'Weekly Reports'
        unique_together = ['user', 'week_start']
        ordering = ['-week_start']
    
    def __str__(self):
        return f"Weekly Report - {self.user.email} ({self.week_start})"
    
    def generate_report(self):
        """Generate weekly report data."""
        from tasks.models import Task
        from datetime import timedelta
        
        # Get tasks for this week
        week_tasks = Task.objects.filter(
            user=self.user,
            created_at__gte=self.week_start,
            created_at__lt=self.week_end + timedelta(days=1)
        )
        
        self.total_tasks = week_tasks.count()
        self.completed_tasks = week_tasks.filter(is_completed=True).count()
        
        if self.total_tasks > 0:
            self.completion_rate = (self.completed_tasks / self.total_tasks) * 100
        
        # Calculate category breakdown
        category_breakdown = {}
        for task in week_tasks:
            cat_id = str(task.category.id)
            if cat_id not in category_breakdown:
                category_breakdown[cat_id] = {'total': 0, 'completed': 0}
            category_breakdown[cat_id]['total'] += 1
            if task.is_completed:
                category_breakdown[cat_id]['completed'] += 1
        
        self.category_stats = category_breakdown
        self.save()