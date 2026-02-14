"""
Gamification Models for TaskCue Backend
Handles points, achievements, streaks, and rewards system
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class UserPoints(models.Model):
    """Track user points and scoring."""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='points')
    
    # Point totals
    total_points = models.PositiveIntegerField(default=0)
    lifetime_points = models.PositiveIntegerField(default=0)
    points_this_week = models.PositiveIntegerField(default=0)
    points_this_month = models.PositiveIntegerField(default=0)
    
    # Level system
    current_level = models.PositiveIntegerField(default=1)
    points_to_next_level = models.PositiveIntegerField(default=100)
    
    # Weekly/monthly resets
    last_weekly_reset = models.DateField(null=True, blank=True)
    last_monthly_reset = models.DateField(null=True, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'user_points'
        verbose_name = 'User Points'
        verbose_name_plural = 'User Points'
    
    def __str__(self):
        return f"{self.user.email} - {self.total_points} points (Level {self.current_level})"
    
    def add_points(self, points, reason="Task completion"):
        """Add points and update level."""
        self.total_points += points
        self.lifetime_points += points
        self.points_this_week += points
        self.points_this_month += points
        
        # Check for level up
        self.check_level_up()
        
        # Log the point transaction
        PointsTransaction.objects.create(
            user=self.user,
            points=points,
            transaction_type='earned',
            reason=reason
        )
        
        self.save()
    
    def check_level_up(self):
        """Check if user has leveled up."""
        # Simple progression: level 1 = 0-99 points, level 2 = 100-299, level 3 = 300-599, etc.
        new_level = (self.total_points // 100) + 1
        
        if new_level > self.current_level:
            old_level = self.current_level
            self.current_level = new_level
            
            # Award level up achievement
            Achievement.award_achievement(self.user, 'level_up', {'new_level': new_level})
            
            # Calculate points needed for next level
            self.points_to_next_level = (new_level * 100) - self.total_points
        else:
            self.points_to_next_level = ((self.current_level) * 100) - self.total_points


class Streak(models.Model):
    """Track user streaks (daily task completion, etc.)."""
    
    STREAK_TYPES = [
        ('daily_tasks', 'Daily Task Completion'),
        ('weekly_goals', 'Weekly Goal Achievement'),
        ('category_focus', 'Category Focus Streak'),
        ('early_completion', 'Early Task Completion'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='streaks')
    streak_type = models.CharField(max_length=20, choices=STREAK_TYPES)
    
    # Streak data
    current_count = models.PositiveIntegerField(default=0)
    best_count = models.PositiveIntegerField(default=0)
    
    # Date tracking
    last_activity_date = models.DateField(null=True, blank=True)
    streak_start_date = models.DateField(null=True, blank=True)
    
    # Metadata
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'user_streaks'
        verbose_name = 'User Streak'
        verbose_name_plural = 'User Streaks'
        unique_together = ['user', 'streak_type']
    
    def __str__(self):
        return f"{self.user.email} - {self.get_streak_type_display()}: {self.current_count} days"
    
    def update_streak(self, activity_date=None):
        """Update streak based on activity."""
        if activity_date is None:
            activity_date = timezone.now().date()
        
        # Check if streak continues
        if self.last_activity_date:
            days_diff = (activity_date - self.last_activity_date).days
            
            if days_diff == 1:  # Consecutive day
                self.current_count += 1
                if self.current_count > self.best_count:
                    self.best_count = self.current_count
            elif days_diff > 1:  # Streak broken
                self.current_count = 1
                self.streak_start_date = activity_date
        else:  # First activity
            self.current_count = 1
            self.streak_start_date = activity_date
        
        self.last_activity_date = activity_date
        self.save()
        
        # Check for streak achievements
        self._check_streak_achievements()
    
    def _check_streak_achievements(self):
        """Check if streak milestones reached."""
        milestones = [7, 30, 90, 365]
        for milestone in milestones:
            if self.current_count == milestone and self.streak_type == 'daily_tasks':
                Achievement.award_achievement(
                    self.user, 
                    f'streak_{milestone}',
                    {'streak_type': self.streak_type, 'days': milestone}
                )


class Achievement(models.Model):
    """User achievements and badges."""
    
    ACHIEVEMENT_TYPES = [
        ('task_milestone', 'Task Milestone'),
        ('streak_milestone', 'Streak Milestone'),
        ('level_up', 'Level Up'),
        ('category_expert', 'Category Expert'),
        ('time_management', 'Time Management'),
        ('consistency', 'Consistency'),
        ('special', 'Special Achievement'),
    ]
    
    # Achievement definition
    achievement_id = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=255)
    description = models.TextField()
    achievement_type = models.CharField(max_length=20, choices=ACHIEVEMENT_TYPES)
    
    # Badge/icon
    icon = models.CharField(max_length=50)
    color = models.CharField(max_length=7)  # Hex color
    
    # Difficulty and rewards
    difficulty = models.CharField(max_length=20, default='easy')  # easy, medium, hard, epic
    points_reward = models.PositiveIntegerField(default=50)
    
    # Requirements
    requirements = models.JSONField(default=dict)  # Flexible requirements definition
    
    # Metadata
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'achievements'
        verbose_name = 'Achievement'
        verbose_name_plural = 'Achievements'
    
    def __str__(self):
        return self.name
    
    @classmethod
    def initialize_achievements(cls):
        """Initialize default achievements."""
        achievements = [
            {
                'achievement_id': 'first_task',
                'name': 'Getting Started',
                'description': 'Complete your first task',
                'achievement_type': 'task_milestone',
                'icon': 'check_circle',
                'color': '#10B981',
                'difficulty': 'easy',
                'points_reward': 25,
                'requirements': {'tasks_completed': 1}
            },
            {
                'achievement_id': 'task_10',
                'name': 'Productive',
                'description': 'Complete 10 tasks',
                'achievement_type': 'task_milestone',
                'icon': 'trending_up',
                'color': '#3B82F6',
                'difficulty': 'easy',
                'points_reward': 50,
                'requirements': {'tasks_completed': 10}
            },
            {
                'achievement_id': 'streak_7',
                'name': 'Week Warrior',
                'description': 'Complete tasks for 7 consecutive days',
                'achievement_type': 'streak_milestone',
                'icon': 'local_fire_department',
                'color': '#F59E0B',
                'difficulty': 'medium',
                'points_reward': 100,
                'requirements': {'daily_streak': 7}
            },
            {
                'achievement_id': 'level_5',
                'name': 'Rising Star',
                'description': 'Reach level 5',
                'achievement_type': 'level_up',
                'icon': 'star',
                'color': '#8B5CF6',
                'difficulty': 'medium',
                'points_reward': 75,
                'requirements': {'level_reached': 5}
            },
        ]
        
        for data in achievements:
            cls.objects.get_or_create(
                achievement_id=data['achievement_id'],
                defaults=data
            )
    
    @classmethod
    def award_achievement(cls, user, achievement_id, context_data=None):
        """Award achievement to user."""
        try:
            achievement = cls.objects.get(achievement_id=achievement_id, is_active=True)
            
            # Check if user already has this achievement
            if UserAchievement.objects.filter(user=user, achievement=achievement).exists():
                return False
            
            # Award the achievement
            user_achievement = UserAchievement.objects.create(
                user=user,
                achievement=achievement,
                context_data=context_data or {}
            )
            
            # Award points
            user_points, created = UserPoints.objects.get_or_create(user=user)
            user_points.add_points(
                achievement.points_reward, 
                f"Achievement: {achievement.name}"
            )
            
            return True
            
        except cls.DoesNotExist:
            return False


class UserAchievement(models.Model):
    """Track which achievements users have earned."""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_achievements')
    achievement = models.ForeignKey(Achievement, on_delete=models.CASCADE)
    
    # Achievement context
    context_data = models.JSONField(default=dict)  # Additional data when earned
    
    # Timestamps
    earned_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'user_achievements'
        verbose_name = 'User Achievement'
        verbose_name_plural = 'User Achievements'
        unique_together = ['user', 'achievement']
        ordering = ['-earned_at']
    
    def __str__(self):
        return f"{self.user.email} - {self.achievement.name}"


class PointsTransaction(models.Model):
    """Track all point transactions for users."""
    
    TRANSACTION_TYPES = [
        ('earned', 'Points Earned'),
        ('bonus', 'Bonus Points'),
        ('penalty', 'Points Penalty'),
        ('reward', 'Reward Purchase'),
        ('gift', 'Gift Points'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='point_transactions')
    
    # Transaction details
    points = models.IntegerField()  # Can be negative for deductions
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    reason = models.CharField(max_length=255)
    
    # Context
    related_task_id = models.UUIDField(null=True, blank=True)  # Link to task if applicable
    related_achievement_id = models.CharField(max_length=50, null=True, blank=True)
    
    # Metadata
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'points_transactions'
        verbose_name = 'Points Transaction'
        verbose_name_plural = 'Points Transactions'
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.user.email} - {self.points} points ({self.reason})"