"""
Django signals for Users app - handles Firestore user profile synchronization
"""
import logging
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from .models import CustomUser, UserProfile
from firebase.services import get_firestore_service

logger = logging.getLogger(__name__)

# Flag to prevent recursive signal triggering
_syncing = False

@receiver(post_save, sender=CustomUser)
def sync_user_to_firestore(sender, instance, created, **kwargs):
    """Sync user profile to Firestore whenever user is created or updated."""
    global _syncing
    
    # Avoid recursive signal triggering and skip if no firebase_uid
    if _syncing or not instance.firebase_uid:
        return
    try:
        _syncing = True
        firestore_service = get_firestore_service()
        
        if not firestore_service.db:
            logger.warning(f"Firestore not available for syncing user {instance.firebase_uid}")
            return
        
        if created:
            # Create new user profile in Firestore
            user_data = {
                'firebase_uid': instance.firebase_uid,
                'email': instance.email,
                'display_name': instance.display_name,
                'role': getattr(instance, 'role', 'user'),
            }
            
            success = firestore_service.create_user_profile(user_data)
            if success:
                logger.info(f"New user profile created in Firestore: {instance.firebase_uid}")
            else:
                logger.warning(f"Failed to create user profile in Firestore: {instance.firebase_uid}")
        else:
            # Update existing user profile in Firestore
            update_data = {
                'email': instance.email,
                'display_name': instance.display_name,
                'role': getattr(instance, 'role', 'user'),
            }
            
            success = firestore_service.update_user_profile(instance.firebase_uid, update_data)
            if success:
                logger.info(f"User profile updated in Firestore: {instance.firebase_uid}")
            else:
                logger.warning(f"Failed to update user profile in Firestore: {instance.firebase_uid}")
                
    except Exception as e:
        logger.error(f"Error in sync_user_to_firestore signal: {e}")
    finally:
        _syncing = False


@receiver(post_save, sender=UserProfile)
def sync_user_profile_preferences(sender, instance, created, **kwargs):
    """Sync user profile preferences to Firestore when profile is updated."""
    try:
        # Skip if user doesn't have firebase_uid
        if not instance.user.firebase_uid:
            logger.debug(f"Skipping profile sync for user without firebase_uid")
            return
        
        firestore_service = get_firestore_service()
        if not firestore_service.db:
            logger.warning(f"Firestore not available for syncing profile {instance.user.firebase_uid}")
            return
        
        # Update user profile preferences in Firestore
        update_data = {
            'profile': {
                'timezone': getattr(instance, 'timezone', 'UTC'),
                'language': getattr(instance, 'language', 'en'),
                'notifications_enabled': getattr(instance, 'notifications_enabled', True),
            },
        }
        
        success = firestore_service.update_user_profile(instance.user.firebase_uid, update_data)
        if success:
            logger.info(f"User profile preferences synced to Firestore: {instance.user.firebase_uid}")
        else:
            logger.warning(f"Failed to sync user profile preferences: {instance.user.firebase_uid}")
            
    except Exception as e:
        logger.error(f"Error in sync_user_profile_preferences signal: {e}")
