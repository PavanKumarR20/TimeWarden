import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    // Request notification permissions
    await _requestPermissions();
  }

  Future<void> _createNotificationChannels() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Create pomodoro timer channel
        const pomodoroChannel = AndroidNotificationChannel(
          'pomodoro_timer',
          'Pomodoro Timer',
          description: 'Ongoing pomodoro timer notifications',
          importance: Importance.low,
          enableVibration: false,
          enableLights: false,
          showBadge: false,
        );

        await androidImplementation.createNotificationChannel(pomodoroChannel);

        // Create habit reminders channel
        const habitChannel = AndroidNotificationChannel(
          'habit_reminders',
          'Habit Reminders',
          description: 'Daily habit reminder notifications',
          importance: Importance.defaultImportance,
        );

        await androidImplementation.createNotificationChannel(habitChannel);

        debugPrint('NotificationService: Notification channels created');
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    debugPrint('NotificationService: Notification tapped!');
    debugPrint('NotificationService: Payload: ${notificationResponse.payload}');

    if (notificationResponse.payload != null) {
      try {
        final payload = jsonDecode(notificationResponse.payload!);
        debugPrint('NotificationService: Parsed payload: $payload');

        // Handle pomodoro notification tap - just open app
        if (payload['type'] == 'pomodoro_notification') {
          debugPrint(
              'NotificationService: Pomodoro notification tapped - opening app');
          return;
        }

        // Navigate to habit detail or open app for other notifications
        debugPrint('NotificationService: Other notification tapped: $payload');
      } catch (e) {
        debugPrint('NotificationService: Error parsing payload: $e');
      }
    } else {
      debugPrint('NotificationService: No payload in notification');
    }
  }

  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required DateTime scheduledTime,
    String? description,
  }) async {
    final payload = jsonEncode({
      'type': 'habit_reminder',
      'habitId': habitId,
      'habitName': habitName,
    });

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Reminders for your daily habits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      categoryIdentifier: 'habit_reminder',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Show immediate notification for now (can be enhanced with proper scheduling later)
    await _flutterLocalNotificationsPlugin.show(
      habitId.hashCode, // Use habit ID hash as notification ID
      'Time for your habit! 🎯',
      '$habitName${description != null ? ' - $description' : ''}',
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleDailyReminder({
    required String habitId,
    required String habitName,
    required int hour,
    required int minute,
    String? description,
  }) async {
    final payload = jsonEncode({
      'type': 'habit_reminder',
      'habitId': habitId,
      'habitName': habitName,
    });

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_habit_reminders',
      'Daily Habit Reminders',
      channelDescription: 'Daily reminders for your habits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      categoryIdentifier: 'daily_habit_reminder',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // For now, show immediate notification (can be enhanced with proper daily scheduling)
    await _flutterLocalNotificationsPlugin.show(
      habitId.hashCode,
      'Daily Habit Reminder 📅',
      '$habitName${description != null ? ' - $description' : ''}',
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> cancelHabitReminder(String habitId) async {
    await _flutterLocalNotificationsPlugin.cancel(habitId.hashCode);
  }

  Future<void> cancelAllReminders() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Pomodoro notification methods
  static const int _pomodoroNotificationId = 999;

  Future<void> showPomodoroRunningNotification({
    required String sessionType,
    required int remainingMinutes,
    required int remainingSeconds,
    required bool isPaused,
    int? totalMinutes,
    int? completedSessions,
    int? totalSessions,
  }) async {
    debugPrint('NotificationService: showPomodoroRunningNotification called');
    debugPrint(
        'NotificationService: Session: $sessionType, Time: $remainingMinutes:${remainingSeconds.toString().padLeft(2, '0')}, Paused: $isPaused');

    final timeDisplay =
        '${remainingMinutes.toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}';

    // Calculate progress percentage for notification
    final totalSeconds = (totalMinutes ?? 25) * 60;
    final remainingTotalSeconds = (remainingMinutes * 60) + remainingSeconds;
    final progressPercentage =
        ((totalSeconds - remainingTotalSeconds) / totalSeconds * 100).round();

    final payload = jsonEncode({
      'type': 'pomodoro_notification',
      'action': 'status',
    });

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pomodoro_timer',
      'Pomodoro Timer',
      channelDescription: 'Ongoing pomodoro timer',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      progress: progressPercentage,
      maxProgress: 100,
      showProgress: true,
      indeterminate: false,
      subText: '${progressPercentage}% complete',
      enableLights: false,
      enableVibration: false,
      playSound: false,
      // Remove action buttons
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      categoryIdentifier: 'pomodoro_timer',
      threadIdentifier: 'pomodoro_timer',
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final title =
        isPaused ? '⏸️ $sessionType Paused' : '⏱️ $sessionType Running';
    final sessionProgress = completedSessions != null && totalSessions != null
        ? ' • ${completedSessions + 1}/$totalSessions'
        : '';
    final body = isPaused
        ? 'Timer paused at $timeDisplay$sessionProgress'
        : '$timeDisplay remaining$sessionProgress';

    debugPrint(
        'NotificationService: Showing notification - Title: $title, Body: $body, Progress: $progressPercentage%');

    await _flutterLocalNotificationsPlugin.show(
      _pomodoroNotificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    debugPrint('NotificationService: Notification should be visible now');
  }

  Future<void> cancelPomodoroNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(_pomodoroNotificationId);
  }
}
