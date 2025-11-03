import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/pomodoro/domain/entities/pomodoro_session.dart';
import '../../features/pomodoro/domain/entities/pomodoro_settings.dart';

class PomodoroBackgroundService {
  static const String _channelId =
      'pomodoro_timer_v2'; // Changed channel ID to force new channel creation
  static const String _channelName = 'Pomodoro Timer';
  static const int _notificationId = 888;

  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Timer? _timer;
  static PomodoroSession? _currentSession;
  static PomodoroSettings? _settings;
  static ServiceInstance?
      _serviceInstance; // Store service instance for immediate broadcasts
  static int _completedWorkSessions = 0;
  static Set<String> _notifiedSessions =
      {}; // Track sessions that were already notified

  static Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Pomodoro timer progress',
      // Use HIGH importance for lock screen visibility (default wasn't enough)
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    const AndroidNotificationChannel alertsChannel = AndroidNotificationChannel(
      'session_alerts',
      'Session Alerts',
      description: 'Pomodoro session completion alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('session_complete'),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertsChannel);

    // Request full-screen intent permission for Android 14+ (required for lock screen notifications)
    final androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestFullScreenIntentPermission();
      print('BackgroundService: Requested full-screen intent permission');
    }

    await FlutterBackgroundService().configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        // No initial notification - will only show when timer starts
        // Remove foregroundServiceNotificationId - we'll manage it ourselves
        // This prevents conflicts between service-managed and manually-updated notifications
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

    // Store service instance for use in handlers
    _serviceInstance = service;

    // Initialize the notification plugin in the background service
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Don't set initial notification - only show when timer actually starts
    // This prevents the "Ready to start" notification from showing

    // Start listening for events from the main app
    service.on('startTimer').listen((event) => _handleStartTimer(event));
    service.on('pauseTimer').listen((event) => _handlePauseTimer());
    service.on('resumeTimer').listen((event) => _handleResumeTimer());
    service.on('stopTimer').listen((event) => _handleStopTimer());
    service
        .on('updateSettings')
        .listen((event) => _handleUpdateSettings(event));
    service
        .on('clearNotificationTracking')
        .listen((event) => _clearNotificationTracking());
    service.on('stopService').listen((event) => _handleStopService());

    // Handle requests for current session state from main app
    service.on('getCurrentSession').listen((event) async {
      final sessionData = await _getCurrentSessionData();
      // Send response back to main app
      service.invoke('currentSessionResponse', sessionData);
    });

    // Periodic timer to update notification and check completion
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_currentSession != null) {
        if (_currentSession!.status == SessionStatus.active) {
          // Only increment timeSpentSeconds by 1 when active (don't recalculate from startTime)
          final newTimeSpent = _currentSession!.timeSpentSeconds + 1;

          _currentSession =
              _currentSession!.copyWith(timeSpentSeconds: newTimeSpent);

          print(
              'BackgroundService: Timer tick - elapsed: ${newTimeSpent}s, remaining: ${_currentSession!.remainingSeconds}s');

          // Save updated session state
          await _saveSessionState();

          // Send current state to main app via service broadcast
          _broadcastSessionState(service);

          if (_currentSession!.remainingSeconds <= 0) {
            await _handleSessionCompleted(service);
          }
        }
        // When paused, we don't increment timeSpentSeconds - it stays frozen

        // Always update notification (for both active and paused states)
        await _updateNotification(service);
      }
    });

    return true;
  }

  @pragma('vm:entry-point')
  static Future<bool> _onBackground(ServiceInstance service) async {
    return true;
  }

  static Future<void> _handleStartTimer(Map<String, dynamic>? event) async {
    print(
        'BackgroundService: _handleStartTimer called with event: $event'); // DEBUG
    if (event == null) {
      print('BackgroundService: _handleStartTimer - event is null!'); // DEBUG
      return;
    }

    final sessionId = event['sessionId'] as String;
    final sessionType = PomodoroType.values[event['sessionType'] as int];
    final durationMinutes = event['durationMinutes'] as int;
    final taskDescription = event['taskDescription'] as String?;
    final startTime =
        DateTime.fromMillisecondsSinceEpoch(event['startTime'] as int);
    final status = SessionStatus.values[event['status'] as int];

    print(
        'BackgroundService: Starting timer with existing session - ID: $sessionId, type: $sessionType, duration: ${durationMinutes}min');

    // Use the session created by the BLoC
    _currentSession = PomodoroSession(
      id: sessionId,
      type: sessionType,
      startTime: startTime,
      durationMinutes: durationMinutes,
      taskDescription: taskDescription,
      status: status,
    );

    print(
        'BackgroundService: Using BLoC session - ID: ${_currentSession!.id}, startTime: ${_currentSession!.startTime}');

    // Save initial session state
    await _saveSessionState();

    // IMPORTANT: Immediately update notification to replace "Ready to start"
    if (_serviceInstance != null) {
      await _updateNotification(_serviceInstance!);
      print(
          'BackgroundService: Immediately updated notification after timer start');
    }
    // Note: Notification will continue to be updated by the periodic timer
  }

  static Future<void> _handlePauseTimer() async {
    print(
        'BackgroundService: _handlePauseTimer() called'); // DEBUG: Check if handler is called
    if (_currentSession != null) {
      print(
          'BackgroundService: Pausing session from ${_currentSession!.status} to paused'); // DEBUG
      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.paused,
        pausedAt: [..._currentSession!.pausedAt, DateTime.now()],
      );
      await _saveSessionState();

      // Immediately broadcast the paused state to prevent sync timer override
      if (_serviceInstance != null) {
        _broadcastSessionState(_serviceInstance!);
        print(
            'BackgroundService: Broadcasted paused state immediately'); // DEBUG
      }
    } else {
      print('BackgroundService: No current session to pause'); // DEBUG
    }
  }

  static Future<void> _handleResumeTimer() async {
    if (_currentSession != null) {
      // Simply change status to active - timeSpentSeconds stays where it was when paused
      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.active,
        resumedAt: [..._currentSession!.resumedAt, DateTime.now()],
      );
      await _saveSessionState();

      // Immediately broadcast the resumed state to prevent sync timer override
      if (_serviceInstance != null) {
        _broadcastSessionState(_serviceInstance!);
      }
      // Note: Notification will be updated by the periodic timer
    }
  }

  static Future<void> _handleStopTimer() async {
    _currentSession = null;
    await _saveSessionState();

    // Clear notification tracking for stopped sessions to allow fresh starts
    _clearNotificationTracking();

    // Immediately broadcast the stopped state (null session) to prevent sync timer override
    if (_serviceInstance != null) {
      _broadcastSessionState(_serviceInstance!);
    }
    // Note: Notification will be updated by the periodic timer
  }

  static Future<Map<String, dynamic>?> _getCurrentSessionData() async {
    try {
      if (_currentSession != null) {
        final sessionData = {
          'type': _currentSession!.type.name,
          'durationMinutes': _currentSession!.durationMinutes,
          'startTime': _currentSession!.startTime.millisecondsSinceEpoch,
          'endTime': _currentSession!.endTime?.millisecondsSinceEpoch,
          'status': _currentSession!.status.name,
          'timeSpentSeconds': _currentSession!.timeSpentSeconds,
          'remainingSeconds': _currentSession!.remainingSeconds,
        };

        print(
            'BackgroundService: Direct session data - ${_currentSession!.timeSpentSeconds}s elapsed');
        return sessionData;
      }

      print('BackgroundService: No active session');
      return null;
    } catch (e) {
      print('BackgroundService: Failed to get current session data: $e');
      return null;
    }
  }

  static Future<void> _saveSessionState() async {
    try {
      // Try file-based approach first (works better across isolates)
      await _saveSessionToFile();

      // Keep SharedPreferences as backup
      final prefs = await SharedPreferences.getInstance();

      if (_currentSession != null) {
        final sessionData = {
          'type': _currentSession!.type.name,
          'durationMinutes': _currentSession!.durationMinutes,
          'startTime': _currentSession!.startTime.millisecondsSinceEpoch,
          'endTime': _currentSession!.endTime?.millisecondsSinceEpoch,
          'status': _currentSession!.status.name,
          'timeSpentSeconds': _currentSession!.timeSpentSeconds,
          'remainingSeconds': _currentSession!.remainingSeconds,
        };

        final jsonString = json.encode(sessionData);
        await prefs.setString('current_pomodoro_session', jsonString);
        print(
            'BackgroundService: Saved session state - ${_currentSession!.timeSpentSeconds}s elapsed');
      } else {
        await prefs.remove('current_pomodoro_session');
        print('BackgroundService: Cleared session state (no active session)');
      }
    } catch (e) {
      print('BackgroundService: Failed to save session state: $e');
    }
  }

  static void _broadcastSessionState(ServiceInstance service) {
    try {
      if (_currentSession != null) {
        final sessionData = {
          'type': _currentSession!.type.name,
          'durationMinutes': _currentSession!.durationMinutes,
          'startTime': _currentSession!.startTime.millisecondsSinceEpoch,
          'endTime': _currentSession!.endTime?.millisecondsSinceEpoch,
          'status': _currentSession!.status.name,
          'timeSpentSeconds': _currentSession!.timeSpentSeconds,
          'remainingSeconds': _currentSession!.remainingSeconds,
        };

        // Broadcast current session state to main app
        service.invoke('sessionStateUpdate', sessionData);
        print(
            'BackgroundService: Broadcasted session state - ${_currentSession!.timeSpentSeconds}s elapsed');
      } else {
        // Broadcast null session (no active session)
        service.invoke('sessionStateUpdate', null);
        print('BackgroundService: Broadcasted null session state');
      }
    } catch (e) {
      print('BackgroundService: Failed to broadcast session state: $e');
    }
  }

  static Future<void> _saveSessionToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pomodoro_session.json');

      if (_currentSession != null) {
        final sessionData = {
          'type': _currentSession!.type.name,
          'durationMinutes': _currentSession!.durationMinutes,
          'startTime': _currentSession!.startTime.millisecondsSinceEpoch,
          'endTime': _currentSession!.endTime?.millisecondsSinceEpoch,
          'status': _currentSession!.status.name,
          'timeSpentSeconds': _currentSession!.timeSpentSeconds,
          'remainingSeconds': _currentSession!.remainingSeconds,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        };

        await file.writeAsString(json.encode(sessionData));
        print(
            'BackgroundService: Saved to file - ${_currentSession!.timeSpentSeconds}s elapsed');
      } else {
        if (await file.exists()) {
          await file.delete();
        }
        print('BackgroundService: Cleared session file (no active session)');
      }
    } catch (e) {
      print('BackgroundService: Failed to save session to file: $e');
    }
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

    // Clear notification tracking when service stops
    _clearNotificationTracking();

    // Show service closed notification
    await _showServiceClosedNotification();

    FlutterBackgroundService().invoke('serviceStopped');
  }

  /// Clear notification tracking to allow fresh notifications for new sessions
  static void _clearNotificationTracking() {
    _notifiedSessions.clear();
    print('BackgroundService: Cleared notification tracking set');
  }

  static Future<void> _handleSessionCompleted(ServiceInstance service) async {
    if (_currentSession == null) return;

    // Check if we already notified for this session to prevent duplicates
    if (_notifiedSessions.contains(_currentSession!.id)) {
      print(
          'BackgroundService: Already notified for session ${_currentSession!.id}, skipping duplicate notification');
      return;
    }

    // Mark this session as notified FIRST to prevent any race conditions
    _notifiedSessions.add(_currentSession!.id);
    print(
        'BackgroundService: Session ${_currentSession!.id} completed, showing notification');

    // Show completion notification with sound
    if (_settings?.enableNotifications == true) {
      final sessionTypeName = _currentSession!.type == PomodoroType.work
          ? 'Work'
          : _currentSession!.type == PomodoroType.longBreak
              ? 'Long Break'
              : 'Break';

      final message = _currentSession!.type == PomodoroType.work
          ? 'Great job! Time for a break.'
          : 'Break time is over. Ready to focus?';

      // Determine which sound to play based on session type
      final soundFileName = _getSoundFileForSession(_currentSession!.type);

      print(
          'BackgroundService: Playing completion sound: $soundFileName for $sessionTypeName');

      // Use platform-level notification with sound
      // This is the ONLY place where completion notifications are shown
      // to avoid duplicates from BLoC
      await _showCompletionNotification(
        sessionType: sessionTypeName,
        message: message,
        playSound: _settings?.enableSounds ?? false,
        enableVibration: _settings?.enableVibration ?? false,
        soundFileName: soundFileName,
      );

      print('BackgroundService: Completion notification shown successfully');
    } else {
      print(
          'BackgroundService: Notifications disabled in settings, skipping notification');
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
        _completedWorkSessions % (_settings?.sessionsUntilLongBreak ?? 4) ==
            0) {
      return 'Long Break';
    }
    return 'Work Session';
  }

  static Future<void> _updateNotification(ServiceInstance service) async {
    if (_currentSession == null) {
      print(
          'BackgroundService: No active session - skipping notification update');
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

    // Calculate progress percentage
    final totalSeconds = _currentSession!.totalDurationSeconds;
    final elapsedSeconds = _currentSession!.timeSpentSeconds;
    final progressPercentage = ((elapsedSeconds / totalSeconds) * 100).round();

    print(
        'BackgroundService: Updating foreground notification - $sessionType $status ${remainingMinutes}:${remainingSeconds.toString().padLeft(2, '0')} ($progressPercentage%)');

    // Use setForegroundNotificationInfo() - the proper API for foreground service notifications
    // This is more reliable for lock screen visibility than using .show()
    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: 'Pomodoro Timer - $sessionType',
        content:
            '$status: ${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')} remaining',
      );
      print('BackgroundService: Foreground notification updated successfully');
    }
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
          visibility: NotificationVisibility.public, // Can show on lock screen
        ),
      ),
    );
  }

  static String _getSoundFileForSession(PomodoroType type) {
    switch (type) {
      case PomodoroType.work:
        return 'work_complete';
      case PomodoroType.shortBreak:
        return 'break_complete';
      case PomodoroType.longBreak:
        return 'break_complete';
    }
  }

  static Future<void> _showCompletionNotification({
    required String sessionType,
    required String message,
    required bool playSound,
    required bool enableVibration,
    required String soundFileName,
  }) async {
    print(
        'BackgroundService: Creating completion notification - Type: $sessionType, Sound: $soundFileName, Play: $playSound');

    await _flutterLocalNotificationsPlugin.show(
      _notificationId + 2,
      'Pomodoro Complete - $sessionType',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'session_alerts',
          'Session Alerts',
          channelDescription: 'Pomodoro session completion alerts',
          playSound: playSound,
          enableVibration: enableVibration,
          priority: Priority.max,
          importance: Importance.max,
          category: AndroidNotificationCategory.alarm,
          sound: playSound
              ? RawResourceAndroidNotificationSound(soundFileName)
              : null,
          // Critical flags for locked screen playback
          visibility: NotificationVisibility.public, // Shows on lock screen
          fullScreenIntent: true, // Can show full-screen and wake device
          channelShowBadge: true,
          autoCancel: true, // Dismissible after tap
          ongoing: false, // Not persistent
          enableLights: true, // LED notification light
          ledColor: const Color(0xFF4CAF50), // Green LED
          ledOnMs: 1000,
          ledOffMs: 500,
          // Audio attributes to ensure sound plays at alarm level
          audioAttributesUsage: AudioAttributesUsage.alarm,
          // Show on lock screen even when device is secured
          showWhen: true,
          when: DateTime.now().millisecondsSinceEpoch,
        ),
      ),
    );

    print('BackgroundService: Notification created and shown');
  }

  // Removed SharedPreferences persistence - keeping simple

  static Future<void> _loadState() async {
    // No persistence - start fresh
    _completedWorkSessions = 0;
    _currentSession = null;
    _notifiedSessions.clear(); // Clear notification history
  }

  static Future<void> stopService() async {
    FlutterBackgroundService().invoke('stopService');
  }

  static Future<void> startService() async {
    await FlutterBackgroundService().startService();
  }

  static Future<void> startTimer({
    required PomodoroSession session,
  }) async {
    try {
      print(
          'PomodoroBackgroundService: Invoking startTimer with session ID: ${session.id}');
      FlutterBackgroundService().invoke('startTimer', {
        'sessionId': session.id,
        'sessionType': session.type.index,
        'durationMinutes': session.durationMinutes,
        'taskDescription': session.taskDescription,
        'startTime': session.startTime.millisecondsSinceEpoch,
        'status': session.status.index,
      });
      print('PomodoroBackgroundService: startTimer invoke call completed');
    } catch (e) {
      print('PomodoroBackgroundService: Error invoking startTimer: $e');
    }
  }

  static Future<void> pauseTimer() async {
    print(
        'PomodoroBackgroundService: Invoking pauseTimer command to background service'); // DEBUG
    FlutterBackgroundService().invoke('pauseTimer');
    print(
        'PomodoroBackgroundService: pauseTimer invoke call completed'); // DEBUG
  }

  static Future<void> resumeTimer() async {
    FlutterBackgroundService().invoke('resumeTimer');
  }

  static Future<void> stopTimer() async {
    FlutterBackgroundService().invoke('stopTimer');
  }

  /// Clear notification tracking to allow fresh notifications for new sessions
  static Future<void> clearNotificationTracking() async {
    FlutterBackgroundService().invoke('clearNotificationTracking');
  }

  static Future<void> updateSettings(PomodoroSettings settings) async {
    final service = FlutterBackgroundService();
    service.invoke('updateSettings', {
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

  // Store the latest session state received from background service broadcasts
  static Map<String, dynamic>? _latestSessionState;
  static bool _isListening = false;

  static Future<Map<String, dynamic>?> getCurrentSessionState() async {
    try {
      final service = FlutterBackgroundService();

      // Check if service is running first
      if (!await service.isRunning()) {
        print('BackgroundService: Service not running');
        return null;
      }

      // Set up listener for session state updates if not already listening
      if (!_isListening) {
        _setupSessionStateListener();
        _isListening = true;
        print('BackgroundService: Set up session state listener');
      }

      // Return the latest broadcasted session state
      if (_latestSessionState != null) {
        print(
            'BackgroundService: Retrieved session from broadcast - ${_latestSessionState!['timeSpentSeconds']}s elapsed');
        return _latestSessionState;
      }

      // Try file-based approach as fallback
      final fileData = await _readSessionFromFile();
      if (fileData != null) {
        print(
            'BackgroundService: Retrieved session from file - ${fileData['timeSpentSeconds']}s elapsed');
        return fileData;
      }

      // Final fallback to SharedPreferences
      print('BackgroundService: Final fallback to SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final sessionDataJson = prefs.getString('current_pomodoro_session');

      if (sessionDataJson != null && sessionDataJson.isNotEmpty) {
        try {
          final sessionData =
              Map<String, dynamic>.from(json.decode(sessionDataJson));
          print(
              'BackgroundService: Retrieved session data from SharedPreferences - ${sessionData['timeSpentSeconds']}s elapsed');
          return sessionData;
        } catch (e) {
          print('BackgroundService: Failed to parse session data: $e');
        }
      }

      print('BackgroundService: No session data available');
      return null;
    } catch (e) {
      print('BackgroundService: Failed to get session state: $e');
      return null;
    }
  }

  static void _setupSessionStateListener() {
    try {
      final service = FlutterBackgroundService();
      service.on('sessionStateUpdate').listen((sessionData) {
        if (sessionData != null) {
          _latestSessionState = Map<String, dynamic>.from(sessionData as Map);
          print(
              'BackgroundService: Received session state broadcast - ${_latestSessionState!['timeSpentSeconds']}s elapsed');
        } else {
          _latestSessionState = null;
          print('BackgroundService: Received null session state broadcast');
        }
      });
    } catch (e) {
      print('BackgroundService: Failed to set up session state listener: $e');
    }
  }

  static Future<Map<String, dynamic>?> _readSessionFromFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pomodoro_session.json');

      if (await file.exists()) {
        final contents = await file.readAsString();
        final sessionData = Map<String, dynamic>.from(json.decode(contents));

        // Check if the data is recent (not stale)
        final lastUpdated = sessionData['lastUpdated'] as int?;
        if (lastUpdated != null) {
          final age = DateTime.now().millisecondsSinceEpoch - lastUpdated;
          if (age > 5000) {
            // 5 seconds
            print('BackgroundService: Session file is stale (${age}ms old)');
            return null;
          }
        }

        print(
            'BackgroundService: Read from file - ${sessionData['timeSpentSeconds']}s elapsed');
        return sessionData;
      }

      print('BackgroundService: Session file does not exist');
      return null;
    } catch (e) {
      print('BackgroundService: Failed to read session from file: $e');
      return null;
    }
  }

  static Future<void> clearSessionState() async {
    try {
      // Clear file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pomodoro_session.json');
      if (await file.exists()) {
        await file.delete();
      }

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_pomodoro_session');
      print(
          'PomodoroBackgroundService: Cleared session state from file and SharedPreferences');
    } catch (e) {
      print('PomodoroBackgroundService: Failed to clear session state: $e');
    }
  }

  static Future<bool> get isRunning async =>
      await FlutterBackgroundService().isRunning();
}
