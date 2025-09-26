import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:logging/logging.dart';

class NotificationService {
  static NotificationService? _instance;
  static FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  static final Logger _logger = Logger('NotificationService');

  NotificationService._();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  // Initialize notification service
  static Future<void> initialize() async {
    // Initialize timezone database
    tz.initializeTimeZones();

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Request permissions
    await _requestPermissions();
  }

  // Handle notification tap
  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Handle notification tap based on payload
      _handleNotificationTap(payload);
    }
  }

  // Handle notification tap logic
  static void _handleNotificationTap(String payload) {
    try {
      // Parse payload and navigate accordingly
      // For example: {"type": "event", "id": "123"}
      _logger.info('Notification tapped with payload: $payload');

      // You can use a navigation service or global navigator key
    } catch (e) {
      _logger.severe('Error handling notification tap', e);
    }
  }

  // Request notification permissions
  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin!
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Request notification permission for Android 13+
      await androidImplementation?.requestNotificationsPermission();

      // Request exact alarm permission for scheduled notifications
      await Permission.notification.request();
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationChannel channel = NotificationChannel.general,
  }) async {
    if (_flutterLocalNotificationsPlugin == null) {
      _logger.warning('Notification service not initialized');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        channel.channelId,
        channel.channelName,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: channel.priority,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        enableVibration: true,
        enableLights: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin!.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      _logger.info('Notification shown - ID: $id, Title: $title');
    } catch (e) {
      _logger.severe('Error showing notification - ID: $id, Title: $title', e);
    }
  }

  // Schedule notification at specific date/time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationChannel channel = NotificationChannel.general,
  }) async {
    if (_flutterLocalNotificationsPlugin == null) {
      _logger.warning('Notification service not initialized');
      return;
    }

    try {
      // Convert DateTime to TZDateTime
      final tz.TZDateTime tzScheduledDate = _convertToTZDateTime(scheduledDate);

      final androidDetails = AndroidNotificationDetails(
        channel.channelId,
        channel.channelName,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: channel.priority,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        enableVibration: true,
        enableLights: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin!.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: payload,
      );
      
      _logger.info('Notification scheduled - ID: $id, Title: $title, Date: $scheduledDate');
    } catch (e) {
      _logger.severe('Error scheduling notification - ID: $id, Title: $title', e);
    }
  }

  // Schedule recurring notification (daily)
  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required DateTime firstNotificationDate,
    required RepeatInterval repeatInterval,
    String? payload,
    NotificationChannel channel = NotificationChannel.general,
  }) async {
    if (_flutterLocalNotificationsPlugin == null) {
      _logger.warning('Notification service not initialized');
      return;
    }

    try {
      // Convert DateTime to TZDateTime
      _convertToTZDateTime(firstNotificationDate);

      final androidDetails = AndroidNotificationDetails(
        channel.channelId,
        channel.channelName,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: channel.priority,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        enableLights: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin!.periodicallyShow(
        id,
        title,
        body,
        repeatInterval,
        notificationDetails,
        payload: payload,
      );
      
      _logger.info('Repeating notification scheduled - ID: $id, Title: $title, Interval: $repeatInterval');
    } catch (e) {
      _logger.severe('Error scheduling repeating notification - ID: $id, Title: $title', e);
    }
  }

  // Schedule event reminder notification
  Future<void> scheduleEventReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    Duration reminderBefore = const Duration(hours: 1),
  }) async {
    final reminderDate = eventDate.subtract(reminderBefore);

    // Don't schedule if reminder time is in the past
    if (reminderDate.isBefore(DateTime.now())) {
      _logger.warning('Event reminder time is in the past - Event: $eventTitle, Reminder: $reminderDate');
      return;
    }

    final payload = '{"type": "event_reminder", "event_id": "$eventId"}';

    await scheduleNotification(
      id: eventId.hashCode,
      title: 'Event Reminder',
      body: '$eventTitle starts in ${reminderBefore.inHours} hour(s)',
      scheduledDate: reminderDate,
      payload: payload,
      channel: NotificationChannel.events,
    );
    
    _logger.info('Event reminder scheduled - Event: $eventTitle, Reminder: $reminderDate');
  }

  // Schedule lucky draw reminder
  Future<void> scheduleLuckyDrawReminder() async {
    // Schedule daily reminder at 10 AM
    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, 10, 0);

    // If it's already past 10 AM today, schedule for tomorrow
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    const payload = '{"type": "lucky_draw_reminder"}';

    await scheduleRepeatingNotification(
      id: 1000, // Fixed ID for lucky draw reminder
      title: 'Lucky Draw Available!',
      body: 'Don\'t forget to spin the wheel today and win amazing prizes!',
      firstNotificationDate: reminderTime,
      repeatInterval: RepeatInterval.daily,
      payload: payload,
      channel: NotificationChannel.rewards,
    );
    
    _logger.info('Lucky draw reminder scheduled - Time: $reminderTime');
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    if (_flutterLocalNotificationsPlugin == null) return;

    try {
      await _flutterLocalNotificationsPlugin!.cancel(id);
      _logger.info('Notification cancelled - ID: $id');
    } catch (e) {
      _logger.severe('Error canceling notification - ID: $id', e);
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (_flutterLocalNotificationsPlugin == null) return;

    try {
      await _flutterLocalNotificationsPlugin!.cancelAll();
      _logger.info('All notifications cancelled');
    } catch (e) {
      _logger.severe('Error canceling all notifications', e);
    }
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (_flutterLocalNotificationsPlugin == null) return [];

    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin!.pendingNotificationRequests();
      _logger.fine('Retrieved ${pendingNotifications.length} pending notifications');
      return pendingNotifications;
    } catch (e) {
      _logger.severe('Error getting pending notifications', e);
      return [];
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final granted = await androidImplementation?.areNotificationsEnabled() ?? false;
      _logger.info('Android notifications enabled: $granted');
      return granted;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
      _logger.info('iOS notifications enabled: $granted');
      return granted;
    }

    _logger.warning('Unknown platform for notification permission check');
    return false;
  }

  // Convert regular DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final location = tz.local;
    return tz.TZDateTime.from(dateTime, location);
  }

  // Convert TZDateTime to regular DateTime (for display)
  DateTime convertTZDateTimeToDateTime(tz.TZDateTime tzDateTime) {
    return DateTime(
      tzDateTime.year,
      tzDateTime.month,
      tzDateTime.day,
      tzDateTime.hour,
      tzDateTime.minute,
      tzDateTime.second,
      tzDateTime.millisecond,
    );
  }

  // Get next scheduled date for repeating notifications
  tz.TZDateTime getNextScheduledDate(DateTime baseDate, RepeatInterval interval) {
    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    var scheduledDate = tz.TZDateTime.from(baseDate, location);

    // Ensure the scheduled date is in the future
    while (scheduledDate.isBefore(now)) {
      switch (interval) {
        case RepeatInterval.everyMinute:
          scheduledDate = scheduledDate.add(const Duration(minutes: 1));
          break;
        case RepeatInterval.hourly:
          scheduledDate = scheduledDate.add(const Duration(hours: 1));
          break;
        case RepeatInterval.daily:
          scheduledDate = scheduledDate.add(const Duration(days: 1));
          break;
        case RepeatInterval.weekly:
          scheduledDate = scheduledDate.add(const Duration(days: 7));
          break;
      }
    }

    _logger.fine('Next scheduled date calculated: $scheduledDate for interval: $interval');
    return scheduledDate;
  }

  // Notification for new rewards
  Future<void> showRewardNotification({
    required String rewardName,
    required String rewardType,
  }) async {
    const payload = '{"type": "new_reward"}';

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🎉 New Reward Earned!',
      body: 'Congratulations! You earned: $rewardName',
      payload: payload,
      channel: NotificationChannel.rewards,
    );
    
    _logger.info('Reward notification shown - Reward: $rewardName, Type: $rewardType');
  }

  // Notification for news updates
  Future<void> showNewsNotification({
    required String newsTitle,
    required String newsId,
  }) async {
    final payload = '{"type": "news_update", "news_id": "$newsId"}';

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '📰 Latest News',
      body: newsTitle,
      payload: payload,
      channel: NotificationChannel.news,
    );
    
    _logger.info('News notification shown - News ID: $newsId, Title: $newsTitle');
  }
}

// Notification channels enum
enum NotificationChannel {
  general('general', 'General', 'General notifications', Importance.defaultImportance, Priority.defaultPriority),
  events('events', 'Events', 'Event reminders and updates', Importance.high, Priority.high),
  rewards('rewards', 'Rewards', 'Reward notifications and lucky draw reminders', Importance.high, Priority.high),
  news('news', 'News', 'News updates and articles', Importance.defaultImportance, Priority.defaultPriority),
  verification('verification', 'Verification', 'Identity verification updates', Importance.high, Priority.high);

  const NotificationChannel(this.channelId, this.channelName, this.description, this.importance, this.priority);

  final String channelId;
  final String channelName;
  final String description;
  final Importance importance;
  final Priority priority;
}

// Helper class for notification payload
class NotificationPayload {
  final String type;
  final Map<String, dynamic> data;

  NotificationPayload({
    required this.type,
    this.data = const {},
  });

  // Create from JSON string
  factory NotificationPayload.fromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = 
          Map<String, dynamic>.from(jsonString as Map);

      return NotificationPayload(
        type: json['type'] as String,
        data: Map<String, dynamic>.from(json),
      );
    } catch (e) {
      final logger = Logger('NotificationPayload');
      logger.warning('Error parsing notification payload: $jsonString', e);
      return NotificationPayload(type: 'unknown');
    }
  }

  // Convert to JSON string
  String toJson() {
    final Map<String, dynamic> json = {
      'type': type,
      ...data,
    };
    return json.toString();
  }
}