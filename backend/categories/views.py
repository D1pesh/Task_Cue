"""
Category Views for TaskCue API
"""
import logging
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.generics import ListAPIView
from django.utils import timezone
from .models import Category, CategoryStats
from .serializers import CategorySerializer, CategoryStatsSerializer

logger = logging.getLogger(__name__)

class CategoryListView(ListAPIView):
    """List all 7 categories."""
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = Category.objects.filter(is_active=True).order_by('id')


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def category_stats(request):
    """Get category statistics for current user."""
    try:
        stats = CategoryStats.objects.filter(user=request.user).select_related('category')
        serializer = CategoryStatsSerializer(stats, many=True)
        return Response({'stats': serializer.data})
        
    except Exception as e:
        logger.error(f"Error getting category stats: {e}")
        return Response({'error': 'Failed to get stats'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def category_analytics(request):
    """Get detailed category analytics."""
    try:
        categories = Category.objects.filter(is_active=True)
        analytics_data = []
        
        for category in categories:
            try:
                stats = CategoryStats.objects.get(user=request.user, category=category)
                weekly_progress = stats.get_weekly_progress()
                
                analytics_data.append({
                    'category_id': category.id,
                    'category_name': category.name,
                    'color': category.color,
                    'total_tasks': stats.total_tasks,
                    'completed_tasks': stats.completed_tasks,
                    'completion_rate': stats.completion_rate,
                    'efficiency_score': stats.efficiency_score,
                    'current_streak': stats.current_streak,
                    'weekly_progress': weekly_progress,
                    'total_points': stats.total_points_earned,
                })
            except CategoryStats.DoesNotExist:
                # User hasn't used this category yet
                analytics_data.append({
                    'category_id': category.id,
                    'category_name': category.name,
                    'color': category.color,
                    'total_tasks': 0,
                    'completed_tasks': 0,
                    'completion_rate': 0.0,
                    'efficiency_score': 0.0,
                    'current_streak': 0,
                    'weekly_progress': {'total': 0, 'completed': 0, 'overdue': 0},
                    'total_points': 0,
                })
        
        return Response({'analytics': analytics_data})
        
    except Exception as e:
        logger.error(f"Error getting category analytics: {e}")
        return Response({'error': 'Failed to get analytics'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def admin_category_stats(request):
    """Admin view for category statistics across all users."""
    if not request.user.is_admin_user:
        return Response({'error': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        from django.db.models import Count, Avg
        
        categories = Category.objects.filter(is_active=True)
        admin_stats = []
        
        for category in categories:
            stats = CategoryStats.objects.filter(category=category)
            
            admin_stats.append({
                'category_id': category.id,
                'category_name': category.name,
                'total_users': stats.count(),
                'avg_completion_rate': stats.aggregate(avg=Avg('completion_rate'))['avg'] or 0.0,
                'total_tasks_all_users': sum(s.total_tasks for s in stats),
                'total_completed_all_users': sum(s.completed_tasks for s in stats),
            })
        
        return Response({'admin_stats': admin_stats})
        
    except Exception as e:
        logger.error(f"Error getting admin category stats: {e}")
        return Response({'error': 'Failed to get admin stats'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def health_check(request):
    """Health check for categories service."""
    try:
        category_count = Category.objects.filter(is_active=True).count()
        stats_count = CategoryStats.objects.count()
        
        return Response({
            'status': 'healthy',
            'service': 'categories',
            'database': 'connected',
            'active_categories': category_count,
            'stats_records': stats_count,
            'timestamp': timezone.now().isoformat()
        })
    except Exception as e:
        return Response({
            'status': 'unhealthy',
            'service': 'categories',
            'error': str(e),
            'timestamp': timezone.now().isoformat()
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)