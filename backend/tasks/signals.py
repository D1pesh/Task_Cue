"""
Django signals for Tasks app - handles Firestore synchronization on model changes
"""
import logging
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.utils import timezone
from .models import Task
from firebase.services import get_firestore_service, get_realtime_sync

logger = logging.getLogger(__name__)

# Flag to prevent recursive signal triggering
_syncing = False

@receiver(post_save, sender=Task)
def sync_task_to_firestore(sender, instance, created, **kwargs):
    """Sync task to Firestore whenever a task is created or updated."""
    global _syncing
    
    # Avoid recursive signal triggering
    if _syncing:
        return
    
    try:
        _syncing = True
        firestore_service = get_firestore_service()
        
        # Skip sync if Firebase is not available or user doesn't have firebase_uid
        if not firestore_service.db or not instance.user.firebase_uid:
            instance.firestore_sync_status = 'pending'
            return
        
        # Prepare task data for Firestore
        task_data = {
            'id': str(instance.id),
            'title': instance.title,
            'description': instance.description,
            'category_id': instance.category_id,
            'priority': instance.priority,
            'status': instance.status,
            'is_completed': instance.is_completed,
            'scheduled_time': instance.scheduled_time.isoformat() if instance.scheduled_time else None,
            'deadline_time': instance.deadline_time.isoformat() if instance.deadline_time else None,
            'estimated_duration': instance.estimated_duration,
            'actual_duration': instance.actual_duration,
            'started_at': instance.started_at.isoformat() if instance.started_at else None,
            'completed_at': instance.completed_at.isoformat() if instance.completed_at else None,
            'points_earned': instance.points_earned,
            'bonus_points': instance.bonus_points,
            'created_at': instance.created_at.isoformat(),
            'updated_at': instance.updated_at.isoformat(),
            'user_firebase_uid': instance.user.firebase_uid,
        }
        
        # Sync to Firestore
        success = firestore_service.sync_task_to_firestore(task_data)
        
        if success:
            # Update sync status directly without triggering another signal
            Task.objects.filter(id=instance.id).update(
                firestore_sync_status='synced',
                last_synced_at=timezone.now()
            )
            logger.info(f"Task {instance.id} synced to Firestore (created={created})")
        else:
            Task.objects.filter(id=instance.id).update(firestore_sync_status='failed')
            logger.warning(f"Failed to sync task {instance.id} to Firestore")
            
    except Exception as e:
        logger.error(f"Error in sync_task_to_firestore signal: {e}")
        try:
            Task.objects.filter(id=instance.id).update(firestore_sync_status='failed')
        except Exception:
            pass
    finally:
        _syncing = False


@receiver(post_delete, sender=Task)
def delete_task_from_firestore(sender, instance, **kwargs):
    """Delete task from Firestore when task is deleted from Django."""
    try:
        firestore_service = get_firestore_service()
        if not firestore_service.db or not instance.user.firebase_uid:
            logger.warning(f"Cannot delete task {instance.id} from Firestore: Firebase not available or user UID missing")
            return
        
        success = firestore_service.delete_task_from_firestore(
            user_firebase_uid=instance.user.firebase_uid,
            task_id=str(instance.id)
        )
        
        if success:
            logger.info(f"Task {instance.id} deleted from Firestore")
        else:
            logger.warning(f"Failed to delete task {instance.id} from Firestore")
            
    except Exception as e:
        logger.error(f"Error in delete_task_from_firestore signal: {e}")
