import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../features/pomodoro/domain/entities/pomodoro_session.dart';
import '../../features/pomodoro/domain/entities/pomodoro_settings.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';

class PomodoroBackgroundService {
  static const String _channelId = 'pomodoro_background_service';
  static const String _channelName = 'Pomodoro Background Service';
  static const int _notificationId = 888;

  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Timer? _timer;
  static PomodoroSession? _currentSession;
  static PomodoroSettings _settings = const PomodoroSettings();
  static int _completedWorkSessions = 0;
  static final AudioService _audioService = AudioService();

  static Future<void> initialize() async {
    await _audioService.initialize();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Pomodoro timer background service',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FlutterBackgroundService().configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Pomodoro Timer',
        initialNotificationContent: 'Timer is running in background',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Load saved state
    await _loadState();

    // Set up notification tap handler
    _flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap - could bring app to foreground
      },
    );

    // Start listening for events from the main app
    service.on('startTimer').listen((event) => _handleStartTimer(event));
    service.on('pauseTimer').listen((event) => _handlePauseTimer());
    service.on('resumeTimer').listen((event) => _handleResumeTimer());
    service.on('stopTimer').listen((event) => _handleStopTimer());
    service
        .on('updateSettings')
        .listen((event) => _handleUpdateSettings(event));
    service.on('stopService').listen((event) => _handleStopService());

    // Periodic timer to update notification and check completion
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_currentSession != null &&
          _currentSession!.status == SessionStatus.active) {
        final actualElapsed =
            DateTime.now().difference(_currentSession!.startTime).inSeconds;

        _currentSession =
            _currentSession!.copyWith(timeSpentSeconds: actualElapsed);

        // Update shared preferences with current state for UI to read
        await _updateSharedPreferences();

        if (_currentSession!.remainingSeconds <= 0) {
          await _handleSessionCompleted(service);
        } else {
          await _updateNotification(service);
        }
      }
    });

    return true;
  }

  @pragma('vm:entry-point')
  static Future<bool> _onBackground(ServiceInstance service) async {
    return true;
  }

  static Future<void> _handleStartTimer(Map<String, dynamic>? event) async {
    if (event == null) return;

    final sessionType = PomodoroType.values[event['sessionType'] as int];
    final durationMinutes = event['durationMinutes'] as int;
    final taskDescription = event['taskDescription'] as String?;

    _currentSession = PomodoroSession(
      id: const Uuid().v4(),
      type: sessionType,
      startTime: DateTime.now(),
      durationMinutes: durationMinutes,
      taskDescription: taskDescription,
      status: SessionStatus.active,
    );

    await _updateSharedPreferences();
    // Note: Notification will be updated by the periodic timer
  }

  static Future<void> _handlePauseTimer() async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(status: SessionStatus.paused);
      await _updateSharedPreferences();
    }
  }

  static Future<void> _handleResumeTimer() async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(status: SessionStatus.active);
      await _updateSharedPreferences();
      // Note: Notification will be updated by the periodic timer
    }
  }

  static Future<void> _handleStopTimer() async {
    _currentSession = null;
    await _updateSharedPreferences();
    // Note: Notification will be updated by the periodic timer
  }

  static Future<void> _handleUpdateSettings(Map<String, dynamic>? event) async {
    if (event == null) return;

    _settings = PomodoroSettings(
      workDurationMinutes: event['workDurationMinutes'] as int,
      shortBreakMinutes: event['shortBreakMinutes'] as int,
      longBreakMinutes: event['longBreakMinutes'] as int,
      sessionsUntilLongBreak: event['sessionsUntilLongBreak'] as int,
      enableNotifications: event['enableNotifications'] as bool,
      enableSounds: event['enableSounds'] as bool,
      enableVibration: event['enableVibration'] as bool,
      soundVolume: event['soundVolume'] as double,
    );
  }

  static Future<void> _handleStopService() async {
    _timer?.cancel();
    _currentSession = null;
    await _updateSharedPreferences();

    // Show service closed notification
    await _showServiceClosedNotification();

    FlutterBackgroundService().invoke('serviceStopped');
  }

  static Future<void> _handleSessionCompleted(ServiceInstance service) async {
    if (_currentSession == null) return;

    // Play completion sound
    if (_settings.enableSounds) {
      if (_currentSession!.type == PomodoroType.work) {
        await _audioService
            .playPomodoroSound(PomodoroSoundType.sessionComplete);
      } else if (_currentSession!.type == PomodoroType.longBreak) {
        await _audioService
            .playPomodoroSound(PomodoroSoundType.finalBreakComplete);
      } else {
        await _audioService.playPomodoroSound(PomodoroSoundType.breakComplete);
      }
    }

    // Show completion notification
    if (_settings.enableNotifications) {
      final notificationService = NotificationService();
      await notificationService.initialize();

      final sessionTypeName = _currentSession!.type == PomodoroType.work
          ? 'Work'
          : _currentSession!.type == PomodoroType.longBreak
              ? 'Long Break'
              : 'Break';

      final message = _currentSession!.type == PomodoroType.work
          ? 'Great job! Time for a break.'
          : 'Break time is over. Ready to focus?';

      await notificationService.showSessionCompletionNotification(
        sessionType: sessionTypeName,
        message: message,
        nextSessionType: _getNextSessionTypeName(),
      );
    }

    // Mark session as completed
    _currentSession = _currentSession!.copyWith(
      status: SessionStatus.completed,
      endTime: DateTime.now(),
      timeSpentSeconds: _currentSession!.totalDurationSeconds,
    );

    if (_currentSession!.type == PomodoroType.work) {
      _completedWorkSessions++;
    }

    await _updateSharedPreferences();

    // Notify main app about completion
    service.invoke('sessionCompleted', {
      'sessionId': _currentSession!.id,
      'sessionType': _currentSession!.type.index,
      'completedWorkSessions': _completedWorkSessions,
    });

    _currentSession = null;
  }

  static String _getNextSessionTypeName() {
    if (_completedWorkSessions > 0 &&
        _completedWorkSessions % _settings.sessionsUntilLongBreak == 0) {
      return 'Long Break';
    }
    return 'Work Session';
  }

  static Future<void> _updateNotification(ServiceInstance service) async {
    if (_currentSession == null) {
      await _flutterLocalNotificationsPlugin.cancel(_notificationId);
      return;
    }

    final remainingMinutes = (_currentSession!.remainingSeconds / 60).floor();
    final remainingSeconds = _currentSession!.remainingSeconds % 60;

    final sessionType = _currentSession!.type == PomodoroType.work
        ? 'Work'
        : _currentSession!.type == PomodoroType.longBreak
            ? 'Long Break'
            : 'Break';

    final status =
        _currentSession!.status == SessionStatus.active ? 'Running' : 'Paused';

    await _flutterLocalNotificationsPlugin.show(
      _notificationId,
      'Pomodoro Timer - $sessionType',
      '$status: ${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')} remaining',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          ongoing: true,
          playSound: false,
          enableVibration: false,
          priority: Priority.low,
          importance: Importance.low,
        ),
      ),
    );
  }

  static Future<void> _showServiceClosedNotification() async {
    await _flutterLocalNotificationsPlugin.show(
      _notificationId + 1,
      'Pomodoro Service Closed',
      'The Pomodoro timer service has been stopped',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          playSound: true,
          enableVibration: true,
          priority: Priority.high,
          importance: Importance.high,
        ),
      ),
    );
  }

  static Future<void> _updateSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentSession != null) {
      final sessionData = {
        'id': _currentSession!.id,
        'type': _currentSession!.type.name,
        'startTime': _currentSession!.startTime.millisecondsSinceEpoch,
        'durationMinutes': _currentSession!.durationMinutes,
        'timeSpentSeconds': _currentSession!.timeSpentSeconds,
        'status': _currentSession!.status.name,
        'taskDescription': _currentSession!.taskDescription,
      };
      await prefs.setString('current_session', jsonEncode(sessionData));
    }
    await prefs.setInt('completed_work_sessions', _completedWorkSessions);
  }

  static Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _completedWorkSessions = prefs.getInt('completed_work_sessions') ?? 0;

    final sessionJson = prefs.getString('current_session');
    if (sessionJson != null) {
      try {
        final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
        final startTime = DateTime.fromMillisecondsSinceEpoch(
            sessionData['startTime'] as int);
        final timeSinceStart = DateTime.now().difference(startTime);

        if (timeSinceStart.inHours < 24) {
          _currentSession = PomodoroSession(
            id: sessionData['id'] as String,
            type: PomodoroType.values.firstWhere(
              (type) => type.name == sessionData['type'] as String,
              orElse: () => PomodoroType.work,
            ),
            startTime: startTime,
            durationMinutes: sessionData['durationMinutes'] as int,
            taskDescription: sessionData['taskDescription'] as String?,
          );

          final totalDuration =
              Duration(minutes: _currentSession!.durationMinutes);
          final elapsed = DateTime.now().difference(_currentSession!.startTime);
          final remaining = totalDuration - elapsed;

          if (remaining.inSeconds > 0) {
            _currentSession = _currentSession!.copyWith(
              timeSpentSeconds: elapsed.inSeconds,
              status: SessionStatus.values.firstWhere(
                (status) => status.name == sessionData['status'] as String,
                orElse: () => SessionStatus.paused,
              ),
            );
          }
        }
      } catch (e) {
        print('Error loading saved session in background service: $e');
        await prefs.remove('current_session');
      }
    }
  }

  static Future<void> stopService() async {
    FlutterBackgroundService().invoke('stopService');
  }

  static Future<void> startService() async {
    await FlutterBackgroundService().startService();
  }

  static Future<void> startTimer({
    required PomodoroType sessionType,
    required int durationMinutes,
    String? taskDescription,
  }) async {
    FlutterBackgroundService().invoke('startTimer', {
      'sessionType': sessionType.index,
      'durationMinutes': durationMinutes,
      'taskDescription': taskDescription,
    });
  }

  static Future<void> pauseTimer() async {
    FlutterBackgroundService().invoke('pauseTimer');
  }

  static Future<void> resumeTimer() async {
    FlutterBackgroundService().invoke('resumeTimer');
  }

  static Future<void> stopTimer() async {
    FlutterBackgroundService().invoke('stopTimer');
  }

  static Future<void> updateSettings(PomodoroSettings settings) async {
    FlutterBackgroundService().invoke('updateSettings', {
      'workDurationMinutes': settings.workDurationMinutes,
      'shortBreakMinutes': settings.shortBreakMinutes,
      'longBreakMinutes': settings.longBreakMinutes,
      'sessionsUntilLongBreak': settings.sessionsUntilLongBreak,
      'enableNotifications': settings.enableNotifications,
      'enableSounds': settings.enableSounds,
      'enableVibration': settings.enableVibration,
      'soundVolume': settings.soundVolume,
    });
  }

  static Future<bool> get isRunning async =>
      await FlutterBackgroundService().isRunning();
}
