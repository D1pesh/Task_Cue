"""
Tasks Models for TaskCue Backend
Handles task creation, management, and two-time system (scheduled + deadline)
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
import uuid

User = get_user_model()


class Task(models.Model):
    """Main task model with two-time system (scheduled + deadline)."""
    
    PRIORITY_CHOICES = [
        (1, 'High'),
        (2, 'Medium'),
        (3, 'Low'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    # Basic Task Information
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    
    # Relationships
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='tasks')
    category = models.ForeignKey('categories.Category', on_delete=models.CASCADE, related_name='tasks')
    
    # Two-Time System
    scheduled_time = models.DateTimeField(help_text="When to start working on this task")
    deadline_time = models.DateTimeField(help_text="When this task must be completed")
    
    # Task Properties
    priority = models.IntegerField(choices=PRIORITY_CHOICES, default=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    is_completed = models.BooleanField(default=False)
    
    # Time Tracking
    estimated_duration = models.PositiveIntegerField(help_text="Estimated duration in minutes", null=True, blank=True)
    actual_duration = models.PositiveIntegerField(help_text="Actual time spent in minutes", null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    # Recurrence (for repeating tasks)
    is_recurring = models.BooleanField(default=False)
    recurrence_pattern = models.CharField(max_length=50, blank=True)  # daily, weekly, monthly
    recurrence_end_date = models.DateTimeField(null=True, blank=True)
    parent_task = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True, related_name='child_tasks')
    
    # Gamification
    points_earned = models.PositiveIntegerField(default=0)
    bonus_points = models.PositiveIntegerField(default=0)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Firestore Sync
    firestore_sync_status = models.CharField(max_length=20, default='pending')
    last_synced_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'tasks'
        verbose_name = 'Task'
        verbose_name_plural = 'Tasks'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['scheduled_time']),
            models.Index(fields=['deadline_time']),
            models.Index(fields=['category', 'priority']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.user.email}"
    
    def save(self, *args, **kwargs):
        """Override save to handle completion logic and point calculation."""
        # Auto-set completed_at when task is completed
        if self.is_completed and not self.completed_at:
            self.completed_at = timezone.now()
            self.status = 'completed'
            
            # Calculate points
            self.calculate_points()
            
            # Update category stats
            self.update_category_stats()
        
        # Validate time logic
        if self.scheduled_time and self.deadline_time:
            if self.scheduled_time > self.deadline_time:
                raise ValueError("Scheduled time cannot be after deadline time")
        
        super().save(*args, **kwargs)
        
        # Sync to Firestore
        self.sync_to_firestore()
    
    def calculate_points(self):
        """Calculate points based on priority and completion timing."""
        if not self.is_completed:
            return
        
        # Base points based on priority
        base_points = {1: 25, 2: 15, 3: 10}  # High, Medium, Low
        self.points_earned = base_points.get(self.priority, 10)
        
        # Bonus for early completion
        if self.completed_at and self.deadline_time:
            if self.completed_at <= self.deadline_time:
                self.bonus_points = 5  # Early/on-time bonus
    
    def update_category_stats(self):
        """Update category statistics after task completion."""
        from categories.models import CategoryStats
        
        stats, created = CategoryStats.objects.get_or_create(
            user=self.user,
            category=self.category,
        )
        stats.update_stats()
    
    def sync_to_firestore(self):
        """Sync task to Firestore for real-time updates."""
        try:
            from firebase.services import get_firestore_service
            firestore_service = get_firestore_service()
            
            task_data = {
                'id': str(self.id),
                'title': self.title,
                'description': self.description,
                'user_firebase_uid': self.user.firebase_uid,
                'category_id': self.category.id,
                'priority': self.priority,
                'status': self.status,
                'is_completed': self.is_completed,
                'scheduled_time': self.scheduled_time.isoformat() if self.scheduled_time else None,
                'deadline_time': self.deadline_time.isoformat() if self.deadline_time else None,
                'created_at': self.created_at.isoformat(),
                'updated_at': self.updated_at.isoformat(),
            }
            
            firestore_service.sync_task_to_firestore(task_data)
            self.firestore_sync_status = 'synced'
            self.last_synced_at = timezone.now()
            
        except Exception as e:
            self.firestore_sync_status = 'error'
            print(f"Firestore sync error: {e}")
    
    @property
    def is_overdue(self):
        """Check if task is overdue."""
        if self.is_completed or not self.deadline_time:
            return False
        return timezone.now() > self.deadline_time
    
    @property
    def time_until_deadline(self):
        """Get time remaining until deadline."""
        if not self.deadline_time:
            return None
        
        now = timezone.now()
        if now > self.deadline_time:
            return None  # Overdue
        
        return self.deadline_time - now
    
    @property
    def time_until_scheduled(self):
        """Get time remaining until scheduled start."""
        if not self.scheduled_time:
            return None
        
        now = timezone.now()
        if now > self.scheduled_time:
            return None  # Past scheduled time
        
        return self.scheduled_time - now


class TaskNote(models.Model):
    """Notes and comments for tasks."""
    
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='notes')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'task_notes'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Note for {self.task.title}"


class TaskAttachment(models.Model):
    """File attachments for tasks."""
    
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='attachments')
    file = models.FileField(upload_to='task_attachments/%Y/%m/%d/')
    filename = models.CharField(max_length=255)
    file_size = models.PositiveIntegerField()
    content_type = models.CharField(max_length=100)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    uploaded_by = models.ForeignKey(User, on_delete=models.CASCADE)
    
    class Meta:
        db_table = 'task_attachments'
        ordering = ['-uploaded_at']
    
    def __str__(self):
        return f"{self.filename} - {self.task.title}"


class TaskHistory(models.Model):
    """Track task changes and history."""
    
    ACTION_CHOICES = [
        ('created', 'Task Created'),
        ('updated', 'Task Updated'),
        ('completed', 'Task Completed'),
        ('cancelled', 'Task Cancelled'),
        ('restored', 'Task Restored'),
        ('deleted', 'Task Deleted'),
    ]
    
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='history')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)
    changes = models.JSONField(default=dict, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'task_history'
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.task.title} - {self.get_action_display()}"