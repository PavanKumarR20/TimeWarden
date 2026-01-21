import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';

/// Service for managing Pomodoro timer alarms
///
/// Wraps the alarm package to provide a clean interface for scheduling
/// and canceling Pomodoro session completion alarms.
class AlarmService {
  static const int _pomodoroAlarmId = 998;

  /// Initialize the alarm service
  /// Must be called before using any other methods
  static Future<void> initialize() async {
    try {
      await Alarm.init();
      debugPrint('AlarmService: Initialized successfully');
    } catch (e) {
      debugPrint('AlarmService: Initialization error: $e');
    }
  }

  /// Schedule an alarm for when the Pomodoro session completes
  ///
  /// [completionTime] - When the session will end
  /// [sessionType] - Type of session (work/break)
  /// [message] - Notification message to display
  Future<void> scheduleSessionCompletion({
    required DateTime completionTime,
    required String sessionType,
    required String message,
  }) async {
    try {
      // Determine audio file based on session type
      final String audioPath = _getAudioPath(sessionType);

      final alarmSettings = AlarmSettings(
        id: _pomodoroAlarmId,
        dateTime: completionTime,
        assetAudioPath: audioPath,
        loopAudio: false,
        vibrate: true,
        warningNotificationOnKill: defaultTargetPlatform == TargetPlatform.iOS,
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: 'Pomodoro Timer',
          body: message,
          stopButton: 'Stop',
        ),
        volumeSettings: VolumeSettings.fixed(
          volume: 0.8,
          volumeEnforced: true,
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);
      debugPrint(
          'AlarmService: Scheduled alarm for ${completionTime.toIso8601String()}');
    } catch (e) {
      debugPrint('AlarmService: Error scheduling alarm: $e');
    }
  }

  /// Cancel the active Pomodoro alarm
  Future<void> cancelSessionAlarm() async {
    try {
      await Alarm.stop(_pomodoroAlarmId);
      debugPrint('AlarmService: Cancelled alarm ID $_pomodoroAlarmId');
    } catch (e) {
      debugPrint('AlarmService: Error canceling alarm: $e');
    }
  }

  /// Check if a Pomodoro alarm is currently set
  bool isAlarmSet() {
    final alarm = Alarm.getAlarm(_pomodoroAlarmId);
    return alarm != null;
  }

  /// Get the audio path based on session type
  String _getAudioPath(String sessionType) {
    if (sessionType.toLowerCase().contains('work')) {
      return 'assets/audio/work_complete.mp3';
    } else if (sessionType.toLowerCase().contains('break')) {
      return 'assets/audio/break_complete.mp3';
    } else {
      return 'assets/audio/session_complete.mp3';
    }
  }
}
