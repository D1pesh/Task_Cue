"""
Task Views for TaskCue API
"""
import logging
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from django.contrib.auth import get_user_model
from django.utils import timezone
from firebase.services import get_firestore_service
from .models import Task, TaskNote, TaskAttachment, TaskHistory
from .serializers import TaskSerializer, TaskCreateSerializer, TaskNoteSerializer

logger = logging.getLogger(__name__)
User = get_user_model()

class TaskListCreateView(ListCreateAPIView):
    """List and create tasks for current user."""
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Task.objects.filter(user=self.request.user).select_related('category')
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return TaskCreateSerializer
        return TaskSerializer
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class TaskDetailView(RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete individual tasks."""
    serializer_class = TaskSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Task.objects.filter(user=self.request.user).select_related('category')


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def complete_task(request, task_id):
    """Mark task as completed."""
    try:
        task = Task.objects.get(id=task_id, user=request.user)
        
        if task.is_completed:
            return Response({'error': 'Task already completed'}, status=status.HTTP_400_BAD_REQUEST)
        
        task.is_completed = True
        task.completed_at = timezone.now()
        task.save()
        
        return Response(TaskSerializer(task).data)
        
    except Task.DoesNotExist:
        return Response({'error': 'Task not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def task_stats(request):
    """Get task statistics for current user."""
    user_tasks = Task.objects.filter(user=request.user)
    
    stats = {
        'total_tasks': user_tasks.count(),
        'completed_tasks': user_tasks.filter(is_completed=True).count(),
        'pending_tasks': user_tasks.filter(is_completed=False).count(),
        'overdue_tasks': user_tasks.filter(
            is_completed=False,
            deadline_time__lt=timezone.now()
        ).count(),
    }
    
    return Response(stats)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def health_check(request):
    """Health check for tasks service."""
    try:
        task_count = Task.objects.count()
        return Response({
            'status': 'healthy',
            'service': 'tasks',
            'database': 'connected',
            'task_count': task_count,
            'timestamp': timezone.now().isoformat()
        })
    except Exception as e:
        return Response({
            'status': 'unhealthy',
            'service': 'tasks',
            'error': str(e),
            'timestamp': timezone.now().isoformat()
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)