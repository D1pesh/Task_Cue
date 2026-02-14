"""
Analytics Views for TaskCue API
"""
import logging
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.utils import timezone
from .models import UserAnalytics, ProductivityInsight, WeeklyReport

logger = logging.getLogger(__name__)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_analytics(request):
    """Get user analytics data."""
    try:
        analytics, created = UserAnalytics.objects.get_or_create(user=request.user)
        
        if created or (timezone.now() - analytics.last_calculated).days > 1:
            analytics.update_insights()
        
        data = {
            'productivity_score': analytics.productivity_score,
            'efficiency_rating': analytics.efficiency_rating,
            'completion_rate_7d': analytics.completion_rate_7d,
            'completion_rate_30d': analytics.completion_rate_30d,
            'current_streak_days': analytics.current_streak_days,
            'longest_streak_days': analytics.longest_streak_days,
            'most_productive_hour': analytics.most_productive_hour,
            'category_distribution': analytics.category_distribution,
            'last_updated': analytics.last_calculated,
        }
        
        return Response(data)
        
    except Exception as e:
        logger.error(f"Error getting user analytics: {e}")
        return Response({'error': 'Failed to get analytics'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def weekly_report(request):
    """Get weekly productivity report."""
    from datetime import datetime, timedelta
    
    # Get current week
    today = timezone.now().date()
    week_start = today - timedelta(days=today.weekday())
    week_end = week_start + timedelta(days=6)
    
    try:
        report, created = WeeklyReport.objects.get_or_create(
            user=request.user,
            week_start=week_start,
            defaults={'week_end': week_end}
        )
        
        if created or not report.category_stats:
            report.generate_report()
        
        data = {
            'week_start': report.week_start,
            'week_end': report.week_end,
            'total_tasks': report.total_tasks,
            'completed_tasks': report.completed_tasks,
            'completion_rate': report.completion_rate,
            'category_stats': report.category_stats,
            'points_earned': report.points_earned,
            'key_insights': report.key_insights,
            'recommendations': report.recommendations,
        }
        
        return Response(data)
        
    except Exception as e:
        logger.error(f"Error generating weekly report: {e}")
        return Response({'error': 'Failed to generate report'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def productivity_insights(request):
    """Get AI-generated productivity insights."""
    try:
        insights = ProductivityInsight.objects.filter(
            user=request.user,
            is_read=False
        ).order_by('-generated_at')[:10]
        
        data = []
        for insight in insights:
            data.append({
                'id': insight.id,
                'type': insight.insight_type,
                'title': insight.title,
                'description': insight.description,
                'confidence_score': insight.confidence_score,
                'is_actionable': insight.is_actionable,
                'generated_at': insight.generated_at,
                'category': insight.category.name if insight.category else None,
            })
        
        return Response({'insights': data})
        
    except Exception as e:
        logger.error(f"Error getting productivity insights: {e}")
        return Response({'error': 'Failed to get insights'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def health_check(request):
    """Health check for analytics service."""
    try:
        analytics_count = UserAnalytics.objects.count()
        return Response({
            'status': 'healthy',
            'service': 'analytics',
            'database': 'connected',
            'analytics_count': analytics_count,
            'timestamp': timezone.now().isoformat()
        })
    except Exception as e:
        return Response({
            'status': 'unhealthy',
            'service': 'analytics',
            'error': str(e),
            'timestamp': timezone.now().isoformat()
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)