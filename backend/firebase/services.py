"""
Firebase Services for TaskCue Backend
Provides Firebase Authentication, Firestore, and real-time sync functionality
"""
import json
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime, timezone

try:
    import firebase_admin
    from firebase_admin import auth, firestore, credentials
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    print("Warning: Firebase Admin SDK not installed. Firebase features will be disabled.")

from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)

class FirebaseService:
    """Main Firebase service class for authentication and Firestore operations."""
    
    def __init__(self):
        if FIREBASE_AVAILABLE:
            try:
                self.db = firestore.client()
                self.auth = auth
            except Exception as e:
                logger.warning(f"Firebase initialization failed: {e}")
                self.db = None
                self.auth = None
        else:
            self.db = None
            self.auth = None
        
    def verify_token(self, id_token: str) -> Optional[Dict[str, Any]]:
        """
        Verify Firebase ID token and return user information.
        
        Args:
            id_token: Firebase ID token from client
            
        Returns:
            Dict with user information or None if invalid
        """
        if not FIREBASE_AVAILABLE or not self.auth:
            logger.warning("Firebase not available for token verification")
            return None
            
        try:
            # Verify the token
            decoded_token = self.auth.verify_id_token(id_token)
            
            # Cache the result for 15 minutes
            cache_key = f"firebase_user_{decoded_token['uid']}"
            cache.set(cache_key, decoded_token, 60 * 15)
            
            return decoded_token
        except Exception as e:
            logger.warning(f"Invalid Firebase token: {e}")
            return None
    
    def get_user_by_uid(self, uid: str) -> Optional[Any]:
        """Get Firebase user by UID."""
        if not FIREBASE_AVAILABLE or not self.auth:
            return None
            
        try:
            return self.auth.get_user(uid)
        except Exception as e:
            logger.warning(f"Firebase user not found: {uid}, error: {e}")
            return None
    
    def create_custom_token(self, uid: str, additional_claims: Dict[str, Any] = None) -> str:
        """Create a custom authentication token."""
        if not FIREBASE_AVAILABLE or not self.auth:
            raise Exception("Firebase not available")
            
        try:
            return self.auth.create_custom_token(uid, additional_claims)
        except Exception as e:
            logger.error(f"Error creating custom token: {e}")
            raise
    
    def set_custom_user_claims(self, uid: str, custom_claims: Dict[str, Any]) -> None:
        """Set custom claims for a user (for role management)."""
        if not FIREBASE_AVAILABLE or not self.auth:
            logger.warning("Firebase not available for setting custom claims")
            return
            
        try:
            self.auth.set_custom_user_claims(uid, custom_claims)
            logger.info(f"Custom claims set for user {uid}: {custom_claims}")
        except Exception as e:
            logger.error(f"Error setting custom claims: {e}")
            raise

class FirestoreService:
    """Firestore database operations for real-time sync."""
    
    def __init__(self):
        if FIREBASE_AVAILABLE:
            try:
                self.db = firestore.client()
            except Exception as e:
                logger.warning(f"Firestore initialization failed: {e}")
                self.db = None
        else:
            self.db = None
        
    def create_user_profile(self, user_data: Dict[str, Any]) -> bool:
        """Create user profile in Firestore."""
        if not self.db:
            logger.warning("Firestore not available for creating user profile")
            return False
            
        try:
            doc_ref = self.db.collection('users').document(user_data['firebase_uid'])
            doc_ref.set({
                'email': user_data['email'],
                'display_name': user_data.get('display_name', ''),
                'role': user_data.get('role', 'user'),
                'created_at': firestore.SERVER_TIMESTAMP,
                'last_active': firestore.SERVER_TIMESTAMP,
                'profile': {
                    'timezone': user_data.get('timezone', 'UTC'),
                    'language': user_data.get('language', 'en'),
                    'theme': user_data.get('theme', 'light'),
                    'notifications_enabled': user_data.get('notifications_enabled', True),
                },
                'stats': {
                    'total_tasks': 0,
                    'completed_tasks': 0,
                    'total_points': 0,
                    'current_streak': 0,
                    'longest_streak': 0,
                }
            })
            logger.info(f"User profile created in Firestore: {user_data['firebase_uid']}")
            return True
        except Exception as e:
            logger.error(f"Error creating user profile in Firestore: {e}")
            return False
    
    def get_user_profile(self, firebase_uid: str) -> Optional[Dict[str, Any]]:
        """Get user profile from Firestore."""
        if not self.db:
            return None
            
        try:
            doc_ref = self.db.collection('users').document(firebase_uid)
            doc = doc_ref.get()
            
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            logger.error(f"Error getting user profile from Firestore: {e}")
            return None
    
    def update_user_profile(self, firebase_uid: str, update_data: Dict[str, Any]) -> bool:
        """Update user profile in Firestore."""
        if not self.db:
            return False
            
        try:
            doc_ref = self.db.collection('users').document(firebase_uid)
            update_data['last_active'] = firestore.SERVER_TIMESTAMP if FIREBASE_AVAILABLE else timezone.now().isoformat()
            doc_ref.update(update_data)
            logger.info(f"User profile updated in Firestore: {firebase_uid}")
            return True
        except Exception as e:
            logger.error(f"Error updating user profile in Firestore: {e}")
            return False
    
    def sync_task_to_firestore(self, task_data: Dict[str, Any]) -> bool:
        """Sync task to Firestore for real-time updates."""
        if not self.db:
            return False
            
        try:
            user_uid = task_data['user_firebase_uid']
            task_id = task_data['id']
            
            # Store in user's tasks subcollection
            doc_ref = self.db.collection('users').document(user_uid).collection('tasks').document(str(task_id))
            
            firestore_data = {
                'id': task_id,
                'title': task_data['title'],
                'description': task_data.get('description', ''),
                'category_id': task_data['category_id'],
                'priority': task_data['priority'],
                'scheduled_time': task_data.get('scheduled_time'),
                'deadline_time': task_data.get('deadline_time'),
                'is_completed': task_data.get('is_completed', False),
                'created_at': task_data.get('created_at'),
                'updated_at': firestore.SERVER_TIMESTAMP if FIREBASE_AVAILABLE else timezone.now().isoformat(),
                'sync_status': 'synced',
            }
            
            doc_ref.set(firestore_data)
            logger.info(f"Task synced to Firestore: {task_id}")
            return True
        except Exception as e:
            logger.error(f"Error syncing task to Firestore: {e}")
            return False
    
    def delete_task_from_firestore(self, user_firebase_uid: str, task_id: int) -> bool:
        """Delete task from Firestore."""
        try:
            doc_ref = self.db.collection('users').document(user_firebase_uid).collection('tasks').document(str(task_id))
            doc_ref.delete()
            logger.info(f"Task deleted from Firestore: {task_id}")
            return True
        except Exception as e:
            logger.error(f"Error deleting task from Firestore: {e}")
            return False
    
    def get_user_tasks(self, user_firebase_uid: str) -> List[Dict[str, Any]]:
        """Get all tasks for a user from Firestore."""
        try:
            tasks_ref = self.db.collection('users').document(user_firebase_uid).collection('tasks')
            docs = tasks_ref.stream()
            
            tasks = []
            for doc in docs:
                task_data = doc.to_dict()
                tasks.append(task_data)
            
            return tasks
        except Exception as e:
            logger.error(f"Error getting user tasks from Firestore: {e}")
            return []
    
    def update_user_stats(self, user_firebase_uid: str, stats_update: Dict[str, Any]) -> bool:
        """Update user statistics in Firestore."""
        try:
            doc_ref = self.db.collection('users').document(user_firebase_uid)
            
            # Use field path notation for nested updates
            update_data = {}
            for key, value in stats_update.items():
                update_data[f'stats.{key}'] = value
            
            update_data['last_active'] = firestore.SERVER_TIMESTAMP
            
            doc_ref.update(update_data)
            logger.info(f"User stats updated in Firestore: {user_firebase_uid}")
            return True
        except Exception as e:
            logger.error(f"Error updating user stats in Firestore: {e}")
            return False
    
    def log_user_activity(self, user_firebase_uid: str, activity_data: Dict[str, Any]) -> bool:
        """Log user activity for analytics."""
        try:
            collection_ref = self.db.collection('user_activities')
            
            activity_log = {
                'user_firebase_uid': user_firebase_uid,
                'timestamp': firestore.SERVER_TIMESTAMP,
                'activity_type': activity_data['activity_type'],
                'details': activity_data.get('details', {}),
                'session_id': activity_data.get('session_id'),
                'platform': activity_data.get('platform', 'unknown'),
            }
            
            collection_ref.add(activity_log)
            return True
        except Exception as e:
            logger.error(f"Error logging user activity: {e}")
            return False

class FirebaseRealtimeSync:
    """Real-time synchronization service for TaskCue."""
    
    def __init__(self):
        self.firestore_service = FirestoreService()
    
    def sync_task_completion(self, user_firebase_uid: str, task_id: int, completed: bool) -> bool:
        """Sync task completion status in real-time."""
        try:
            doc_ref = self.firestore_service.db.collection('users').document(user_firebase_uid).collection('tasks').document(str(task_id))
            
            update_data = {
                'is_completed': completed,
                'completed_at': firestore.SERVER_TIMESTAMP if completed else None,
                'updated_at': firestore.SERVER_TIMESTAMP,
            }
            
            doc_ref.update(update_data)
            
            # Log activity
            activity_data = {
                'activity_type': 'task_completed' if completed else 'task_uncompleted',
                'details': {'task_id': task_id},
            }
            self.firestore_service.log_user_activity(user_firebase_uid, activity_data)
            
            return True
        except Exception as e:
            logger.error(f"Error syncing task completion: {e}")
            return False
    
    def sync_gamification_update(self, user_firebase_uid: str, points_earned: int, 
                                achievement_unlocked: str = None) -> bool:
        """Sync gamification updates in real-time."""
        try:
            # Update user stats
            stats_update = {'total_points': firestore.Increment(points_earned)}
            self.firestore_service.update_user_stats(user_firebase_uid, stats_update)
            
            # Log achievement if unlocked
            if achievement_unlocked:
                activity_data = {
                    'activity_type': 'achievement_unlocked',
                    'details': {
                        'achievement': achievement_unlocked,
                        'points_earned': points_earned,
                    },
                }
                self.firestore_service.log_user_activity(user_firebase_uid, activity_data)
                
                # Store achievement in user's achievements subcollection
                achievement_ref = self.firestore_service.db.collection('users').document(user_firebase_uid).collection('achievements')
                achievement_ref.add({
                    'achievement_name': achievement_unlocked,
                    'earned_at': firestore.SERVER_TIMESTAMP,
                    'points_earned': points_earned,
                })
            
            return True
        except Exception as e:
            logger.error(f"Error syncing gamification update: {e}")
            return False

# Global instances
firebase_service = FirebaseService()
firestore_service = FirestoreService()
realtime_sync = FirebaseRealtimeSync()

def get_firebase_service() -> FirebaseService:
    """Get Firebase service instance."""
    return firebase_service

def get_firestore_service() -> FirestoreService:
    """Get Firestore service instance."""
    return firestore_service

def get_realtime_sync() -> FirebaseRealtimeSync:
    """Get real-time sync service instance."""
    return realtime_sync