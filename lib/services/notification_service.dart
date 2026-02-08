import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Function(String)? _onNotificationTapped;

  /// Set callback for when notification is tapped
  static void setNotificationTapCallback(Function(String) callback) {
    _onNotificationTapped = callback;
  }

  /// Initialize the notification service
  static Future<bool> initialize() async {
    if (_initialized) return true;

    if (kIsWeb) {
      // Web doesn't support flutter_local_notifications
      _initialized = true;
      return false;
    }

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      bool? result = await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      if (result == true) {
        // Create notification channel for Android
        await _createNotificationChannel();
        _initialized = true;
        return true;
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
    
    _initialized = true;
    return false;
  }

  /// Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'taskcue_reminders',
      'Task Reminders',
      description: 'Notifications for scheduled tasks',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Handle notification response (when user taps notification)
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    
    // Navigate to specific task when notification is tapped
    if (response.payload != null && _onNotificationTapped != null) {
      _onNotificationTapped!(response.payload!);
    }
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    bool granted = true;

    if (androidPlugin != null) {
      granted = await androidPlugin.requestNotificationsPermission() ?? false;
    }

    if (iosPlugin != null) {
      granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }

    return granted;
  }

  /// Schedule notification for a task
  static Future<void> scheduleTaskReminder(Task task) async {
    if (!_initialized || kIsWeb) return;
    
    if (task.scheduledDateTime == null) return;

    try {
      // Cancel any existing notification for this task
      await cancelTaskNotification(task);

      final scheduledDate = tz.TZDateTime.from(
        task.scheduledDateTime!,
        tz.local,
      );

      // Only schedule if the time is in the future
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('Cannot schedule notification for past time: $scheduledDate');
        return;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'taskcue_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for scheduled tasks',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        task.id.hashCode, // Use task ID hash as notification ID
        '⏰ Time to work on: ${task.title}',
        (task.description?.isNotEmpty ?? false)
            ? task.description!
            : 'It\'s time to start working on this task!',
        scheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: task.id, // Pass task ID for handling taps
      );

      debugPrint('Scheduled notification for task: ${task.title} at $scheduledDate');
      
    } catch (e) {
      debugPrint('Error scheduling notification for task ${task.title}: $e');
    }
  }

  /// Cancel notification for a specific task
  static Future<void> cancelTaskNotification(Task task) async {
    if (!_initialized || kIsWeb) return;
    
    try {
      await _notificationsPlugin.cancel(task.id.hashCode);
      debugPrint('Cancelled notification for task: ${task.title}');
    } catch (e) {
      debugPrint('Error cancelling notification for task ${task.title}: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (!_initialized || kIsWeb) return;
    
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('Cancelled all notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Show immediate notification for task start reminder
  static Future<void> showTaskStartReminder(Task task) async {
    if (!_initialized || kIsWeb) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'taskcue_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for scheduled tasks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'start_task',
          '▶️ Start Task',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'snooze_10',
          '⏰ Snooze 10min',
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        task.id.hashCode,
        '🚀 Ready to start: ${task.title}?',
        (task.description?.isNotEmpty ?? false)
            ? task.description!
            : 'Your scheduled time has arrived!',
        notificationDetails,
        payload: task.id,
      );
      
      debugPrint('Showed task start reminder for: ${task.title}');
    } catch (e) {
      debugPrint('Error showing task start reminder: $e');
    }
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized || kIsWeb) return [];
    
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    
    if (!_initialized) {
      await initialize();
    }

    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        return await androidPlugin.areNotificationsEnabled() ?? false;
      }
      
      // For iOS, assume enabled if initialization was successful
      return _initialized;
    } catch (e) {
      debugPrint('Error checking notification permissions: $e');
      return false;
    }
  }
}