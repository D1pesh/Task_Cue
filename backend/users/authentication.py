"""
Firebase Authentication Backend for Django REST Framework
Handles Firebase token verification and user authentication
"""
import logging
from typing import Optional, Tuple
from django.contrib.auth.backends import BaseBackend
from django.contrib.auth import get_user_model
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed
from firebase.services import get_firebase_service, get_firestore_service

logger = logging.getLogger(__name__)
User = get_user_model()

class FirebaseBackend(BaseBackend):
    """Django authentication backend for Firebase users."""
    
    def authenticate(self, request, firebase_token=None, **kwargs):
        """Authenticate user with Firebase token."""
        if firebase_token is None:
            return None
        
        firebase_service = get_firebase_service()
        firestore_service = get_firestore_service()
        
        # Verify Firebase token
        decoded_token = firebase_service.verify_token(firebase_token)
        if not decoded_token:
            return None
        
        firebase_uid = decoded_token.get('uid')
        email = decoded_token.get('email')
        
        if not firebase_uid or not email:
            return None
        
        try:
            # Try to get existing user
            user = User.objects.get(firebase_uid=firebase_uid)
            
            # Update user information if changed
            if user.email != email:
                user.email = email
                user.save()
                
            user.update_last_active()
            return user
            
        except User.DoesNotExist:
            # Create new user
            try:
                # Get Firebase user details
                firebase_user = firebase_service.get_user_by_uid(firebase_uid)
                if not firebase_user:
                    return None
                
                # Create Django user
                user = User.objects.create_user(
                    username=email,  # Use email as username
                    email=email,
                    firebase_uid=firebase_uid,
                    display_name=firebase_user.display_name or '',
                    phone_number=firebase_user.phone_number or '',
                    is_verified=firebase_user.email_verified,
                )
                
                # Create user profile
                from .models import UserProfile
                UserProfile.objects.create(user=user)
                
                # Create Firestore profile
                firestore_service.create_user_profile({
                    'firebase_uid': firebase_uid,
                    'email': email,
                    'display_name': firebase_user.display_name or '',
                    'role': 'user',
                })
                
                logger.info(f"New user created: {email}")
                return user
                
            except Exception as e:
                logger.error(f"Error creating user: {e}")
                return None
    
    def get_user(self, user_id):
        """Get user by ID."""
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None


class FirebaseAuthentication(BaseAuthentication):
    """DRF Authentication class for Firebase tokens."""
    
    keyword = 'Bearer'
    
    def authenticate(self, request):
        """Authenticate the request using Firebase token."""
        auth_header = request.META.get('HTTP_AUTHORIZATION')
        
        if not auth_header:
            return None
        
        try:
            # Extract token from header
            parts = auth_header.split()
            
            if len(parts) != 2 or parts[0] != self.keyword:
                return None
            
            firebase_token = parts[1]
            
            # Use Django authentication backend
            from django.contrib.auth import authenticate
            user = authenticate(request=request, firebase_token=firebase_token)
            
            if user is None:
                raise AuthenticationFailed('Invalid Firebase token')
            
            if not user.is_active:
                raise AuthenticationFailed('User account is disabled')
            
            # Create or update session
            self._create_or_update_session(request, user)
            
            return (user, firebase_token)
            
        except Exception as e:
            logger.error(f"Authentication error: {e}")
            raise AuthenticationFailed(f'Authentication failed: {str(e)}')
    
    def authenticate_header(self, request):
        """Return the authentication header."""
        return f'{self.keyword} realm="api"'
    
    def _create_or_update_session(self, request, user):
        """Create or update user session."""
        try:
            from .models import UserSession
            
            # Get session info from request
            user_agent = request.META.get('HTTP_USER_AGENT', '')
            ip_address = self._get_client_ip(request)
            platform = self._detect_platform(user_agent)
            
            # Try to get existing active session
            session = UserSession.objects.filter(
                user=user,
                is_active=True,
                ip_address=ip_address,
                platform=platform
            ).first()
            
            if session:
                # Update existing session
                from django.utils import timezone
                session.last_activity = timezone.now()
                session.save()
            else:
                # Create new session
                UserSession.objects.create(
                    user=user,
                    platform=platform,
                    ip_address=ip_address,
                    user_agent=user_agent[:1000],  # Limit length
                )
                
                # End old sessions (keep only 3 active sessions)
                old_sessions = UserSession.objects.filter(
                    user=user,
                    is_active=True
                ).order_by('-started_at')[3:]
                
                for old_session in old_sessions:
                    old_session.end_session()
                    
        except Exception as e:
            logger.warning(f"Error managing session: {e}")
    
    def _get_client_ip(self, request):
        """Get client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    def _detect_platform(self, user_agent):
        """Detect platform from user agent."""
        user_agent_lower = user_agent.lower()
        
        if 'android' in user_agent_lower:
            return 'android'
        elif 'iphone' in user_agent_lower or 'ipad' in user_agent_lower:
            return 'ios'
        elif 'electron' in user_agent_lower:
            return 'desktop'
        else:
            return 'web'