"""
Categories Models for TaskCue Backend
7 fixed categories for task organization
"""
from django.db import models
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.conf import settings

User = get_user_model()

class Category(models.Model):
    """Fixed category model - 7 immutable categories."""
    
    CATEGORY_CHOICES = [
        (1, 'Work'),
        (2, 'Personal'),
        (3, 'Health'),
        (4, 'Learning'),
        (5, 'Finance'),
        (6, 'Social'),
        (7, 'Home'),
    ]
    
    CATEGORY_COLORS = {
        1: '#3B82F6',  # Work - Blue
        2: '#10B981',  # Personal - Green
        3: '#EF4444',  # Health - Red
        4: '#8B5CF6',  # Learning - Purple
        5: '#F59E0B',  # Finance - Orange
        6: '#EC4899',  # Social - Pink
        7: '#06B6D4',  # Home - Cyan
    }
    
    CATEGORY_ICONS = {
        1: 'work',
        2: 'person',
        3: 'health_and_safety',
        4: 'school',
        5: 'account_balance',
        6: 'people',
        7: 'home',
    }
    
    CATEGORY_DESCRIPTIONS = {
        1: 'Professional tasks and projects',
        2: 'Personal activities and goals',
        3: 'Fitness, medical, wellness tasks',
        4: 'Education, courses, skill development',
        5: 'Budget, bills, financial planning',
        6: 'Family, friends, social activities',
        7: 'Household, maintenance, organization',
    }
    
    id = models.IntegerField(primary_key=True, choices=CATEGORY_CHOICES)
    name = models.CharField(max_length=50)
    color = models.CharField(max_length=7)  # Hex color
    icon = models.CharField(max_length=50)
    description = models.TextField()
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'categories'
        verbose_name = 'Category'
        verbose_name_plural = 'Categories'
        ordering = ['id']
    
    def __str__(self):
        return f"{self.name} ({self.get_id_display()})"
    
    @classmethod
    def initialize_categories(cls):
        """Initialize the 7 fixed categories."""
        for category_id, name in cls.CATEGORY_CHOICES:
            category, created = cls.objects.get_or_create(
                id=category_id,
                defaults={
                    'name': name,
                    'color': cls.CATEGORY_COLORS[category_id],
                    'icon': cls.CATEGORY_ICONS[category_id],
                    'description': cls.CATEGORY_DESCRIPTIONS[category_id],
                }
            )
            if created:
                print(f"Created category: {name}")
    
    def save(self, *args, **kwargs):
        """Override save to prevent changes to fixed data."""
        if self.pk:  # Updating existing category
            # Only allow updating is_active field
            original = Category.objects.get(pk=self.pk)
            self.name = original.name
            self.color = original.color
            self.icon = original.icon
            self.description = original.description
        super().save(*args, **kwargs)


class CategoryStats(models.Model):
    """Statistics for category usage by users."""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='category_stats')
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='user_stats')
    
    # Task Statistics
    total_tasks = models.IntegerField(default=0)
    completed_tasks = models.IntegerField(default=0)
    pending_tasks = models.IntegerField(default=0)
    overdue_tasks = models.IntegerField(default=0)
    
    # Time Statistics  
    total_time_spent = models.DurationField(default=timezone.timedelta)
    average_completion_time = models.DurationField(null=True, blank=True)
    
    # Performance Metrics
    completion_rate = models.FloatField(default=0.0)  # Percentage
    on_time_completion_rate = models.FloatField(default=0.0)  # Percentage
    
    # Points and Gamification
    total_points_earned = models.IntegerField(default=0)
    
    # Timestamps
    first_task_created = models.DateTimeField(null=True, blank=True)
    last_task_completed = models.DateTimeField(null=True, blank=True)
    last_updated = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'category_stats'
        verbose_name = 'Category Statistics'
        verbose_name_plural = 'Category Statistics'
        unique_together = ['user', 'category']
        indexes = [
            models.Index(fields=['user', 'category']),
            models.Index(fields=['completion_rate']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.category.name} Stats"
    
    def update_stats(self):
        """Recalculate all statistics for this user-category combination."""
        # Import here to avoid circular import - Task will be created later
        try:
            from tasks.models import Task
            user_tasks = Task.objects.filter(user=self.user, category=self.category)
            
            # Basic counts
            self.total_tasks = user_tasks.count()
            self.completed_tasks = user_tasks.filter(is_completed=True).count()
            
            # Calculate completion rate
            if self.total_tasks > 0:
                self.completion_rate = (self.completed_tasks / self.total_tasks) * 100
            else:
                self.completion_rate = 0.0
            
            self.last_activity = timezone.now()
            self.save()
            
        except ImportError:
            # Tasks model doesn't exist yet, skip update
            pass
        self.completed_tasks = user_tasks.filter(is_completed=True).count()
        self.pending_tasks = user_tasks.filter(is_completed=False).count()
        
        # Calculate overdue tasks
        now = timezone.now()
        self.overdue_tasks = user_tasks.filter(
            is_completed=False,
            deadline_time__lt=now
        ).count()
        
        # Calculate completion rate
        if self.total_tasks > 0:
            self.completion_rate = (self.completed_tasks / self.total_tasks) * 100
        else:
            self.completion_rate = 0.0
        
        # Calculate on-time completion rate
        on_time_completed = user_tasks.filter(
            is_completed=True,
            completed_at__lte=models.F('deadline_time')
        ).count()
        
        if self.completed_tasks > 0:
            self.on_time_completion_rate = (on_time_completed / self.completed_tasks) * 100
        else:
            self.on_time_completion_rate = 0.0
        
        # Update timestamps
        first_task = user_tasks.order_by('created_at').first()
        if first_task:
            self.first_task_created = first_task.created_at
        
        last_completed_task = user_tasks.filter(is_completed=True).order_by('-completed_at').first()
        if last_completed_task:
            self.last_task_completed = last_completed_task.completed_at
        
        self.save()
    
    @property
    def productivity_score(self):
        """Calculate a productivity score (0-100) based on various metrics."""
        if self.total_tasks == 0:
            return 0
        
        # Weighted scoring
        completion_weight = 0.4
        on_time_weight = 0.3
        consistency_weight = 0.3
        
        # Consistency based on task creation frequency
        consistency_score = min(self.total_tasks * 10, 100)  # Max 100 for 10+ tasks
        
        score = (
            self.completion_rate * completion_weight +
            self.on_time_completion_rate * on_time_weight +
            consistency_score * consistency_weight
        )
        
        return round(score, 1)