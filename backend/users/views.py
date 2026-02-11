"""
User Views for TaskCue API
"""
import logging
from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.generics import RetrieveUpdateAPIView, ListAPIView
from django.contrib.auth import get_user_model
from django.utils import timezone
from firebase.services import get_firestore_service
from .models import UserProfile, UserSession, UserActivity
from .serializers import (
    UserSerializer, UpdateProfileSerializer, UserSessionSerializer,
    UserActivitySerializer, AdminUserSerializer
)

logger = logging.getLogger(__name__)
User = get_user_model()

class CurrentUserView(RetrieveUpdateAPIView):
    """Get and update current user profile."""
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user


class UpdateProfileView(APIView):
    """Update user profile."""
    permission_classes = [permissions.IsAuthenticated]
    
    def put(self, request):
        serializer = UpdateProfileSerializer(request.user, data=request.data, partial=True)
        
        if serializer.is_valid():
            user = serializer.save()
            
            # Sync to Firestore
            firestore_service = get_firestore_service()
            profile_data = {
                'profile.display_name': user.display_name,
                'profile.phone_number': user.phone_number,
            }
            
            if hasattr(user, 'profile'):
                profile = user.profile
                profile_data.update({
                    'profile.timezone': profile.timezone,
                    'profile.language': profile.language,
                    'profile.theme': profile.theme,
                    'profile.notifications_enabled': profile.notifications_enabled,
                })
            
            firestore_service.update_user_profile(user.firebase_uid, profile_data)
            
            return Response(UserSerializer(user).data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserSessionsView(ListAPIView):
    """List user sessions."""
    serializer_class = UserSessionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return UserSession.objects.filter(
            user=self.request.user
        ).order_by('-started_at')[:10]


class LogoutView(APIView):
    """Logout user (end current session)."""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        # End current session
        user_agent = request.META.get('HTTP_USER_AGENT', '')
        ip_address = self._get_client_ip(request)
        
        session = UserSession.objects.filter(
            user=request.user,
            is_active=True,
            ip_address=ip_address
        ).first()
        
        if session:
            session.end_session()
        
        # Log activity
        UserActivity.objects.create(
            user=request.user,
            session=session,
            activity_type='logout',
            ip_address=ip_address,
            user_agent=user_agent[:1000]
        )
        
        return Response({'message': 'Successfully logged out'})
    
    def _get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class VerifyTokenView(APIView):
    """Verify Firebase token."""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        return Response({
            'valid': True,
            'user': UserSerializer(request.user).data
        })


class DeleteAccountView(APIView):
    """Deactivate user account."""
    permission_classes = [permissions.IsAuthenticated]
    
    def delete(self, request):
        user = request.user
        
        # Deactivate instead of delete (for data integrity)
        user.is_active = False
        user.save()
        
        # End all sessions
        UserSession.objects.filter(user=user, is_active=True).update(
            ended_at=timezone.now(),
            is_active=False
        )
        
        # Log activity
        UserActivity.objects.create(
            user=user,
            activity_type='account_deactivated',
            ip_address=self._get_client_ip(request)
        )
        
        logger.info(f"User account deactivated: {user.email}")
        
        return Response({'message': 'Account deactivated successfully'})


# Admin Views
class AdminUsersView(ListAPIView):
    """Admin view to list all users."""
    serializer_class = AdminUserSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        if not self.request.user.is_admin_user:
            return User.objects.none()
        
        return User.objects.all().select_related('profile').order_by('-created_at')


class AdminUserDetailView(RetrieveUpdateAPIView):
    """Admin view for user details."""
    serializer_class = AdminUserSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        if not self.request.user.is_admin_user:
            return User.objects.none()
        
        return User.objects.all().select_related('profile')


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def admin_user_stats(request):
    """Get user statistics for admin dashboard."""
    if not request.user.is_admin_user:
        return Response({'error': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    from django.db.models import Count, Q
    from datetime import timedelta
    
    now = timezone.now()
    last_24h = now - timedelta(hours=24)
    last_7d = now - timedelta(days=7)
    last_30d = now - timedelta(days=30)
    
    stats = {
        'total_users': User.objects.count(),
        'active_users': User.objects.filter(is_active=True).count(),
        'verified_users': User.objects.filter(is_verified=True).count(),
        'premium_users': User.objects.filter(is_premium=True).count(),
        'new_users_24h': User.objects.filter(created_at__gte=last_24h).count(),
        'new_users_7d': User.objects.filter(created_at__gte=last_7d).count(),
        'new_users_30d': User.objects.filter(created_at__gte=last_30d).count(),
        'active_sessions': UserSession.objects.filter(is_active=True).count(),
        'user_activities_24h': UserActivity.objects.filter(timestamp__gte=last_24h).count(),
        'role_distribution': User.objects.values('role').annotate(count=Count('role')),
    }
    
    return Response(stats)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def health_check(request):
    """Health check for users service."""
    try:
        # Test database connection
        user_count = User.objects.count()
        
        return Response({
            'status': 'healthy',
            'service': 'users',
            'database': 'connected',
            'user_count': user_count,
            'timestamp': timezone.now().isoformat()
        })
    except Exception as e:
        return Response({
            'status': 'unhealthy',
            'service': 'users',
            'error': str(e),
            'timestamp': timezone.now().isoformat()
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)