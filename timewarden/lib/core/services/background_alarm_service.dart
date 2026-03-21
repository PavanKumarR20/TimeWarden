import 'dart:async';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';

/// Simple background service for Pomodoro timer alarms
class BackgroundAlarmService {
  static const int _alarmId = 12345;
  static final BackgroundAlarmService _instance =
      BackgroundAlarmService._internal();
  factory BackgroundAlarmService() => _instance;
  BackgroundAlarmService._internal();

  final NotificationService _notificationService = NotificationService();

  /// Initialize the service
  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    await _notificationService.initialize();
  }

  /// Schedule an alarm for session completion
  Future<bool> scheduleAlarm({
    required DateTime completionTime,
    required String sessionType,
    required String nextSessionType,
  }) async {
    try {
      // Cancel any existing alarm
      await cancelAlarm();

      // Store session info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alarm_session_type', sessionType);
      await prefs.setString('alarm_next_session_type', nextSessionType);

      // Schedule the alarm
      final success = await AndroidAlarmManager.oneShotAt(
        completionTime,
        _alarmId,
        _alarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
      );

      return success;
    } catch (e) {
      debugPrint('BackgroundAlarmService: Error scheduling alarm: $e');
      return false;
    }
  }

  /// Cancel the scheduled alarm
  Future<void> cancelAlarm() async {
    await AndroidAlarmManager.cancel(_alarmId);
  }
}

/// Background callback function
@pragma('vm:entry-point')
void _alarmCallback() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    final sessionType = prefs.getString('alarm_session_type') ?? 'Work';
    final nextSessionType =
        prefs.getString('alarm_next_session_type') ?? 'Break';

    // Create notification service instance
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Show notification
    await notificationService.showSessionCompletionNotification(
      sessionType: sessionType,
      message: _getCompletionMessage(sessionType),
      nextSessionType: nextSessionType,
    );
  } catch (e) {
    debugPrint('BackgroundAlarmService: Error in callback: $e');
  }
}

String _getCompletionMessage(String sessionType) {
  switch (sessionType) {
    case 'Work':
      return 'Great job! Time for a break.';
    case 'Long Break':
      return 'Session complete! Ready to start fresh?';
    default:
      return 'Break time is over. Ready to focus?';
  }
}
