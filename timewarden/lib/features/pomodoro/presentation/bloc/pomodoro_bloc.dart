import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/entities/pomodoro_settings.dart';
import '../../domain/entities/pomodoro_statistics.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/notification_service.dart';
import 'pomodoro_event.dart';
import 'pomodoro_state.dart';

class PomodoroBloc extends Bloc<PomodoroEvent, PomodoroState> {
  Timer? _timer;
  PomodoroSession? _currentSession;
  PomodoroSettings _settings = const PomodoroSettings();
  final List<PomodoroSession> _sessions = [];
  int _completedWorkSessions = 0;
  final NotificationService _notificationService = NotificationService();

  PomodoroBloc() : super(const PomodoroInitial()) {
    on<PomodoroLoadRequested>(_onLoadRequested);
    on<PomodoroStartRequested>(_onStartRequested);
    on<PomodoroPauseRequested>(_onPauseRequested);
    on<PomodoroResumeRequested>(_onResumeRequested);
    on<PomodoroStopRequested>(_onStopRequested);
    on<PomodoroTick>(_onTick);
    on<PomodoroCompleted>(_onCompleted);
    on<PomodoroNextSessionRequested>(_onNextSessionRequested);
    on<PomodoroSkipBreakRequested>(_onSkipBreakRequested);
    on<PomodoroSettingsUpdated>(_onSettingsUpdated);
    on<PomodoroHistoryLoadRequested>(_onHistoryLoadRequested);
  }

  // Persistence methods
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('completed_work_sessions', _completedWorkSessions);

    // Save current session if exists
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
    } else {
      await prefs.remove('current_session');
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _completedWorkSessions = prefs.getInt('completed_work_sessions') ?? 0;

    // Load current session if exists
    final sessionJson = prefs.getString('current_session');
    if (sessionJson != null) {
      try {
        final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;

        // Check if session was saved recently (within last 24 hours)
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

          // Update remaining time based on current time
          final totalDuration =
              Duration(minutes: _currentSession!.durationMinutes);
          final elapsed = DateTime.now().difference(_currentSession!.startTime);
          final remaining = totalDuration - elapsed;

          if (remaining.inSeconds > 0) {
            final timeSpent = elapsed.inSeconds;
            _currentSession = _currentSession!.copyWith(
              timeSpentSeconds: timeSpent,
              status: SessionStatus.values.firstWhere(
                (status) => status.name == sessionData['status'] as String,
                orElse: () => SessionStatus.paused,
              ),
            );
          } else {
            // Session has expired, clear it
            _currentSession = null;
            await prefs.remove('current_session');
          }
        }
      } catch (e) {
        print('Error loading saved session: $e');
        await prefs.remove('current_session');
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(
    PomodoroLoadRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    emit(const PomodoroLoading());

    try {
      // Load saved state
      await _loadState();

      // If we have a saved session, emit the appropriate state
      if (_currentSession != null) {
        if (_currentSession!.status == SessionStatus.paused) {
          emit(PomodoroPaused(
            currentSession: _currentSession!,
            settings: _settings,
            completedWorkSessions: _completedWorkSessions,
            isLongBreakNext: _isLongBreakNext(),
          ));
        } else if (_currentSession!.status == SessionStatus.active) {
          // Resume the timer if it was running
          _startTimer();
          emit(PomodoroRunning(
            currentSession: _currentSession!,
            settings: _settings,
            completedWorkSessions: _completedWorkSessions,
            isLongBreakNext: _isLongBreakNext(),
          ));
        } else {
          emit(PomodoroReady(
            settings: _settings,
            completedWorkSessions: _completedWorkSessions,
            isLongBreakNext: _isLongBreakNext(),
          ));
        }
      } else {
        emit(PomodoroReady(
          settings: _settings,
          completedWorkSessions: _completedWorkSessions,
          isLongBreakNext: _isLongBreakNext(),
        ));
      }
    } catch (e) {
      emit(PomodoroError('Failed to load Pomodoro: $e'));
    }
  }

  Future<void> _onStartRequested(
    PomodoroStartRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    try {
      HapticService.buttonTap();
      print(
          'PomodoroBloc: Starting new session, notifications enabled: ${_settings.enableNotifications}');

      final sessionType = _getNextSessionType();
      final duration = _getDurationForType(sessionType);

      _currentSession = PomodoroSession(
        id: const Uuid().v4(),
        type: sessionType,
        durationMinutes: duration,
        startTime: DateTime.now(),
        status: SessionStatus.active,
        taskDescription: event.taskDescription,
      );

      _startTimer();

      emit(PomodoroRunning(
        currentSession: _currentSession!,
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
      ));

      // Save state
      await _saveState();

      // Show notification
      print('PomodoroBloc: About to show notification');
      await _updateNotification();
      print('PomodoroBloc: Notification shown');
    } catch (e) {
      print('PomodoroBloc: Error starting session: $e');
      emit(PomodoroError('Failed to start session: $e'));
    }
  }

  Future<void> _onPauseRequested(
    PomodoroPauseRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    if (_currentSession != null) {
      HapticService.buttonTap();
      _timer?.cancel();

      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.paused,
        pausedAt: [..._currentSession!.pausedAt, DateTime.now()],
      );

      emit(PomodoroPaused(
        currentSession: _currentSession!,
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
      ));

      // Save state
      await _saveState();

      // Update notification to show paused state
      await _updateNotification();
    }
  }

  Future<void> _onResumeRequested(
    PomodoroResumeRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    if (_currentSession != null) {
      HapticService.buttonTap();

      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.active,
        resumedAt: [..._currentSession!.resumedAt, DateTime.now()],
      );

      _startTimer();

      emit(PomodoroRunning(
        currentSession: _currentSession!,
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
      ));

      // Save state
      await _saveState();

      // Update notification to show running state
      await _updateNotification();
    }
  }

  Future<void> _onStopRequested(
    PomodoroStopRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    HapticService.buttonTap();
    _timer?.cancel();

    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.cancelled,
        endTime: DateTime.now(),
      );
      _sessions.add(_currentSession!);
    }

    _currentSession = null;

    // Save state (clear saved session)
    await _saveState();

    emit(PomodoroReady(
      settings: _settings,
      completedWorkSessions: _completedWorkSessions,
      isLongBreakNext: _isLongBreakNext(),
    ));

    // Cancel notification
    await _cancelNotification();
  }

  Future<void> _onTick(
    PomodoroTick event,
    Emitter<PomodoroState> emit,
  ) async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        timeSpentSeconds: event.secondsElapsed,
      );

      if (_currentSession!.remainingSeconds <= 0) {
        add(const PomodoroCompleted());
      } else {
        emit(PomodoroRunning(
          currentSession: _currentSession!,
          settings: _settings,
          completedWorkSessions: _completedWorkSessions,
          isLongBreakNext: _isLongBreakNext(),
        ));

        // Update notification every second for real-time updates
        await _updateNotification();
      }
    }
  }

  Future<void> _onCompleted(
    PomodoroCompleted event,
    Emitter<PomodoroState> emit,
  ) async {
    _timer?.cancel();

    if (_currentSession != null) {
      // Provide completion feedback
      if (_settings.enableVibration) {
        HapticService.successAction();
      }

      // Show notification
      if (_settings.enableNotifications) {
        NotificationService().scheduleHabitReminder(
          habitId: _currentSession!.id,
          habitName: '${_currentSession!.displayType} Complete!',
          scheduledTime: DateTime.now(),
          description: _currentSession!.type == PomodoroType.work
              ? 'Great job! Time for a break.'
              : 'Break time is over. Ready to focus?',
        );
      }

      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.completed,
        endTime: DateTime.now(),
        timeSpentSeconds: _currentSession!.totalDurationSeconds,
      );

      _sessions.add(_currentSession!);

      if (_currentSession!.type == PomodoroType.work) {
        _completedWorkSessions++;
      }

      final nextSessionType = _getNextSessionType();

      emit(PomodoroSessionCompleted(
        completedSession: _currentSession!,
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
        nextSessionType: nextSessionType,
      ));
    }

    _currentSession = null;

    // Save state (clear current session since it's completed)
    await _saveState();

    // Cancel the ongoing timer notification since session is complete
    await _cancelNotification();
  }

  Future<void> _onNextSessionRequested(
    PomodoroNextSessionRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    emit(PomodoroReady(
      settings: _settings,
      completedWorkSessions: _completedWorkSessions,
      isLongBreakNext: _isLongBreakNext(),
    ));
  }

  Future<void> _onSkipBreakRequested(
    PomodoroSkipBreakRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    add(const PomodoroStartRequested());
  }

  Future<void> _onSettingsUpdated(
    PomodoroSettingsUpdated event,
    Emitter<PomodoroState> emit,
  ) async {
    _settings = event.settings as PomodoroSettings;
    // Save settings to storage (implement later)

    if (state is PomodoroReady) {
      emit(PomodoroReady(
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
      ));
    }
  }

  Future<void> _onHistoryLoadRequested(
    PomodoroHistoryLoadRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    try {
      final today = event.date ?? DateTime.now();
      final todayStats = PomodoroStatistics.fromSessions(today, _sessions);

      // Generate weekly stats
      final weeklyStats = <PomodoroStatistics>[];
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dayStats = PomodoroStatistics.fromSessions(date, _sessions);
        weeklyStats.add(dayStats);
      }

      emit(PomodoroHistoryLoaded(
        sessions: _sessions,
        todayStats: todayStats,
        weeklyStats: weeklyStats,
        settings: _settings,
      ));
    } catch (e) {
      emit(PomodoroError('Failed to load history: $e'));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession != null) {
        final elapsed = _currentSession!.timeSpentSeconds + 1;
        add(PomodoroTick(elapsed));
      }
    });
  }

  PomodoroType _getNextSessionType() {
    if (_completedWorkSessions > 0 &&
        _completedWorkSessions % _settings.sessionsUntilLongBreak == 0) {
      return PomodoroType.longBreak;
    }

    // If last session was work, next should be break
    if (_sessions.isNotEmpty) {
      final lastSession = _sessions.last;
      if (lastSession.type == PomodoroType.work && lastSession.isCompleted) {
        return _isLongBreakNext()
            ? PomodoroType.longBreak
            : PomodoroType.shortBreak;
      }
    }

    return PomodoroType.work;
  }

  int _getDurationForType(PomodoroType type) {
    switch (type) {
      case PomodoroType.work:
        return _settings.workDurationMinutes;
      case PomodoroType.shortBreak:
        return _settings.shortBreakMinutes;
      case PomodoroType.longBreak:
        return _settings.longBreakMinutes;
    }
  }

  bool _isLongBreakNext() {
    return _completedWorkSessions > 0 &&
        _completedWorkSessions % _settings.sessionsUntilLongBreak == 0;
  }

  Future<void> _updateNotification() async {
    if (_currentSession != null && _settings.enableNotifications) {
      final remainingSeconds = _currentSession!.remainingSeconds;
      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;

      // Calculate session progress
      final totalMinutes = _currentSession!.durationMinutes;
      final currentSessionInCycle =
          _completedWorkSessions % _settings.sessionsUntilLongBreak;

      print(
          'PomodoroBloc: Updating notification - ${minutes}:${seconds.toString().padLeft(2, '0')} remaining, paused: ${_currentSession!.status == SessionStatus.paused}');
      print(
          'PomodoroBloc: Session progress: $currentSessionInCycle/${_settings.sessionsUntilLongBreak}, total duration: ${totalMinutes}min');

      await _notificationService.showPomodoroRunningNotification(
        sessionType: _currentSession!.displayType,
        remainingMinutes: minutes,
        remainingSeconds: seconds,
        isPaused: _currentSession!.status == SessionStatus.paused,
        totalMinutes: totalMinutes,
        completedSessions: currentSessionInCycle,
        totalSessions: _settings.sessionsUntilLongBreak,
      );
    } else {
      print(
          'PomodoroBloc: Not updating notification - session: ${_currentSession != null}, notifications enabled: ${_settings.enableNotifications}');
    }
  }

  Future<void> _cancelNotification() async {
    await _notificationService.cancelPomodoroNotification();
  }
}
