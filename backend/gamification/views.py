"""
Gamification Views for TaskCue API
"""
import logging
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.utils import timezone
from .models import UserPoints, UserAchievement, Streak, Achievement

logger = logging.getLogger(__name__)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_points(request):
    """Get user points and level information."""
    try:
        points, created = UserPoints.objects.get_or_create(user=request.user)
        
        data = {
            'total_points': points.total_points,
            'lifetime_points': points.lifetime_points,
            'current_level': points.current_level,
            'points_to_next_level': points.points_to_next_level,
            'points_this_week': points.points_this_week,
            'points_this_month': points.points_this_month,
        }
        
        return Response(data)
        
    except Exception as e:
        logger.error(f"Error getting user points: {e}")
        return Response({'error': 'Failed to get points'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_achievements(request):
    """Get user achievements."""
    try:
        user_achievements = UserAchievement.objects.filter(
            user=request.user
        ).select_related('achievement')
        
        achievements = []
        for ua in user_achievements:
            achievements.append({
                'id': ua.achievement.achievement_id,
                'name': ua.achievement.name,
                'description': ua.achievement.description,
                'type': ua.achievement.achievement_type,
                'icon': ua.achievement.icon,
                'color': ua.achievement.color,
                'difficulty': ua.achievement.difficulty,
                'points_reward': ua.achievement.points_reward,
                'earned_at': ua.earned_at,
                'context_data': ua.context_data,
            })
        
        return Response({'achievements': achievements})
        
    except Exception as e:
        logger.error(f"Error getting user achievements: {e}")
        return Response({'error': 'Failed to get achievements'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def leaderboard(request):
    """Get user leaderboard."""
    try:
        # Get top 10 users by points this month
        top_users = UserPoints.objects.select_related('user').order_by('-points_this_month')[:10]
        
        leaderboard_data = []
        for i, points in enumerate(top_users, 1):
            leaderboard_data.append({
                'rank': i,
                'user_name': points.user.display_name or points.user.email.split('@')[0],
                'points': points.points_this_month,
                'level': points.current_level,
                'is_current_user': points.user == request.user,
            })
        
        # Find current user's rank if not in top 10
        current_user_rank = None
        if request.user.id not in [p.user.id for p in top_users]:
            current_user_points = UserPoints.objects.filter(user=request.user).first()
            if current_user_points:
                higher_scored_users = UserPoints.objects.filter(
                    points_this_month__gt=current_user_points.points_this_month
                ).count()
                current_user_rank = higher_scored_users + 1
        
        return Response({
            'leaderboard': leaderboard_data,
            'current_user_rank': current_user_rank,
        })
        
    except Exception as e:
        logger.error(f"Error getting leaderboard: {e}")
        return Response({'error': 'Failed to get leaderboard'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def award_points(request):
    """Award points to user (for testing or admin actions)."""
    try:
        points_amount = request.data.get('points', 0)
        reason = request.data.get('reason', 'Manual award')
        
        if not request.user.is_admin_user and points_amount > 100:
            return Response({'error': 'Cannot award more than 100 points'}, status=status.HTTP_403_FORBIDDEN)
        
        user_points, created = UserPoints.objects.get_or_create(user=request.user)
        user_points.add_points(points_amount, reason)
        
        return Response({
            'message': f'Awarded {points_amount} points',
            'new_total': user_points.total_points,
            'new_level': user_points.current_level,
        })
        
    except Exception as e:
        logger.error(f"Error awarding points: {e}")
        return Response({'error': 'Failed to award points'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def health_check(request):
    """Health check for gamification service."""
    try:
        points_count = UserPoints.objects.count()
        achievements_count = Achievement.objects.count()
        
        return Response({
            'status': 'healthy',
            'service': 'gamification',
            'database': 'connected',
            'points_records': points_count,
            'achievements_available': achievements_count,
            'timestamp': timezone.now().isoformat()
        })
    except Exception as e:
        return Response({
            'status': 'unhealthy',
            'service': 'gamification',
            'error': str(e),
            'timestamp': timezone.now().isoformat()
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)