import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

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

        // Create session alerts channel for session completion sounds
        const sessionAlertsChannel = AndroidNotificationChannel(
          'session_alerts',
          'Session Alerts',
          description: 'Session completion and break notifications with sound',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('session_complete'),
        );

        await androidImplementation
            .createNotificationChannel(sessionAlertsChannel);

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
      // Request standard notification permission
      await Permission.notification.request();

      // For SCHEDULE_EXACT_ALARM on Android 12+, we need to use Android's
      // AlarmManager.canScheduleExactAlarms() and open settings manually
      // The permission_handler package can check status but can't request it
      // Users must manually enable "Alarms & reminders" in app settings
      final alarmPermission = await Permission.scheduleExactAlarm.status;
      debugPrint(
          'NotificationService: Exact alarm permission status: $alarmPermission');

      if (!alarmPermission.isGranted) {
        debugPrint('NotificationService: Exact alarm permission not granted.');
        debugPrint(
            'NotificationService: Users must enable "Alarms & reminders" in Settings > Apps > Time Warden');
        // Note: On Android 12+, user must manually enable this in settings
        // The app will still work but scheduled notifications may not fire precisely
      }

      debugPrint('NotificationService: Android permissions requested');
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
      icon: '@mipmap/launcher_icon',
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
      icon: '@mipmap/launcher_icon',
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
      icon: '@mipmap/launcher_icon',
      progress: progressPercentage,
      maxProgress: 100,
      showProgress: true,
      indeterminate: false,
      subText: '$progressPercentage% complete',
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

  /// Show session completion notification with sound for background alerts
  Future<void> showSessionCompletionNotification({
    required String sessionType,
    required String message,
    String? nextSessionType,
  }) async {
    debugPrint('NotificationService: Showing session completion notification');
    debugPrint('NotificationService: Type: $sessionType, Message: $message');

    // Determine which custom sound to play based on session type
    String customSoundFile;
    if (sessionType == 'Work') {
      customSoundFile = 'work_complete'; // Custom work completion sound
    } else if (sessionType == 'Long Break') {
      customSoundFile = 'session_complete'; // Victory fanfare for long break
    } else {
      customSoundFile = 'break_complete'; // Break completion sound
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'session_alerts',
      'Session Alerts',
      channelDescription:
          'Session completion and break notifications with sound',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(customSoundFile),
      icon: '@mipmap/launcher_icon',
      autoCancel: true,
      fullScreenIntent: false,
      // Add these for better background behavior
      ongoing: false,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      // Category for alarms to bypass Do Not Disturb
      category: AndroidNotificationCategory.alarm,
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      categoryIdentifier: 'session_completion',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: '$customSoundFile.mp3',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final title = sessionType == 'Work'
        ? '✅ Work Session Complete!'
        : sessionType == 'Break'
            ? '☕ Break Time Over!'
            : '🎉 Session Complete!';

    final body =
        nextSessionType != null ? '$message\nNext: $nextSessionType' : message;

    debugPrint(
        'NotificationService: Session completion - Title: $title, Body: $body');
    debugPrint('NotificationService: Using custom sound: $customSoundFile');

    await _flutterLocalNotificationsPlugin.show(
      999, // Different ID for session completion notifications
      title,
      body,
      platformChannelSpecifics,
    );

    debugPrint('NotificationService: Session completion notification shown');
  }

  /// Schedule a session completion notification to fire at a specific time
  /// This ensures the sound plays even when the app is backgrounded
  Future<void> scheduleSessionCompletionNotification({
    required DateTime scheduledTime,
    required String sessionType,
    required String message,
    String? nextSessionType,
  }) async {
    debugPrint(
        'NotificationService: Scheduling session completion notification');
    debugPrint('NotificationService: Scheduled for: $scheduledTime');
    debugPrint('NotificationService: Type: $sessionType, Message: $message');

    // Determine which custom sound to play based on session type
    String customSoundFile;
    if (sessionType == 'Work') {
      customSoundFile = 'work_complete'; // Custom work completion sound
    } else if (sessionType == 'Long Break') {
      customSoundFile = 'session_complete'; // Victory fanfare for long break
    } else {
      customSoundFile = 'break_complete'; // Break completion sound
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'session_alerts',
      'Session Alerts',
      channelDescription:
          'Session completion and break notifications with sound',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(customSoundFile),
      icon: '@mipmap/launcher_icon',
      autoCancel: true,
      fullScreenIntent: true, // Try to show even when phone is locked
      ongoing: false,
      showWhen: true,
      when: scheduledTime.millisecondsSinceEpoch,
      category: AndroidNotificationCategory.alarm,
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      categoryIdentifier: 'session_completion',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: '$customSoundFile.mp3',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final title = sessionType == 'Work'
        ? '✅ Work Session Complete!'
        : sessionType == 'Break'
            ? '☕ Break Time Over!'
            : '🎉 Session Complete!';

    final body =
        nextSessionType != null ? '$message\nNext: $nextSessionType' : message;

    debugPrint('NotificationService: Scheduling - Title: $title, Body: $body');
    debugPrint('NotificationService: Using custom sound: $customSoundFile');

    // Convert DateTime to TZDateTime
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    debugPrint(
        'NotificationService: Current time: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('NotificationService: Scheduled time (TZ): $tzScheduledTime');
    debugPrint(
        'NotificationService: Time until notification: ${tzScheduledTime.difference(tz.TZDateTime.now(tz.local)).inSeconds} seconds');

    // Use zonedSchedule for precise timing
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        998, // Different ID for scheduled notifications
        title,
        body,
        tzScheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint(
          'NotificationService: Session completion notification scheduled successfully with ID 998');

      // Verify the notification was scheduled
      final pending =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint(
          'NotificationService: Pending notifications count: ${pending.length}');
      for (var notification in pending) {
        debugPrint(
            'NotificationService: Pending notification ID ${notification.id}: ${notification.title}');
      }
    } catch (e) {
      debugPrint('NotificationService: ERROR scheduling notification: $e');
      rethrow;
    }
  }

  /// Cancel scheduled session completion notification
  Future<void> cancelScheduledSessionNotification() async {
    debugPrint('NotificationService: Cancelling scheduled notification ID 998');
    await _flutterLocalNotificationsPlugin.cancel(998);
    debugPrint('NotificationService: Cancelled scheduled session notification');

    // Verify it was cancelled
    final pending =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    debugPrint(
        'NotificationService: Pending notifications after cancel: ${pending.length}');
  }
}
