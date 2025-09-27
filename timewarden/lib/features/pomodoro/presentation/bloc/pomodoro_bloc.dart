import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:uuid/uuid.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/entities/pomodoro_settings.dart';
import '../../domain/entities/pomodoro_statistics.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/pomodoro_background_service.dart';
import 'pomodoro_event.dart';
import 'pomodoro_state.dart';

class PomodoroBloc extends Bloc<PomodoroEvent, PomodoroState> {
  Timer? _timer;
  Timer? _syncTimer; // Timer to sync with background service
  PomodoroSession? _currentSession;
  PomodoroSettings _settings = const PomodoroSettings();
  final List<PomodoroSession> _sessions = [];
  int _completedWorkSessions = 0;
  final NotificationService _notificationService = NotificationService();
  final AudioService _audioService = AudioService();

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
    on<PomodoroTimeSyncRequested>(_onTimeSyncRequested);
    on<PomodoroResetRequested>(_onResetRequested);

    // Initialize audio service
    _initializeAudioService();

    // Start sync timer to periodically sync with background service
    _startSyncTimer();
  }

  Future<void> _initializeAudioService() async {
    try {
      await _audioService.initialize();
      _audioService.setEnabled(_settings.enableSounds);
      _audioService.setVolume(_settings.soundVolume);
    } catch (e) {
      print('Error initializing audio service: $e');
    }
  }

  // Persistence methods
  Future<void> _saveState() async {
    // No persistence - removed to keep simple Pomodoro functionality
  }

  Future<void> _loadState() async {
    // No persistence - start fresh each time
    _completedWorkSessions = 0;
    _currentSession = null;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _syncTimer?.cancel();
    _audioService.dispose();
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
          // Start background service if not running
          final isServiceRunning = await PomodoroBackgroundService.isRunning;
          if (!isServiceRunning) {
            await PomodoroBackgroundService.startService();
            // Resume the timer in background service
            await PomodoroBackgroundService.resumeTimer();
          }
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
      print('PomodoroBloc: Start requested - _settings: $_settings');
      HapticService.pomodoroStart();
      print(
          'PomodoroBloc: Starting new session, notifications enabled: ${_settings.enableNotifications}');

      print('PomodoroBloc: Getting next session type...');
      final sessionType = _getNextSessionType();
      print('PomodoroBloc: Session type: $sessionType');

      print('PomodoroBloc: Getting duration for type...');
      final duration = _getDurationForType(sessionType);
      print('PomodoroBloc: Duration: $duration');

      print('PomodoroBloc: Creating PomodoroSession...');
      _currentSession = PomodoroSession(
        id: const Uuid().v4(),
        type: sessionType,
        durationMinutes: duration,
        startTime: DateTime.now(),
        status: SessionStatus.active,
        taskDescription: event.taskDescription,
      );
      print('PomodoroBloc: Session created successfully');

      // Play appropriate start sound
      if (sessionType == PomodoroType.work) {
        print('PomodoroBloc: Playing work session start sound');
        await _audioService.playPomodoroSound(PomodoroSoundType.sessionStart);
      } else {
        print('PomodoroBloc: Playing break session start sound');
        await _audioService.playPomodoroSound(PomodoroSoundType.breakStart);
      }

      // Start background service if not running
      final isServiceRunning = await PomodoroBackgroundService.isRunning;
      if (!isServiceRunning) {
        await PomodoroBackgroundService.startService();
      }

      // Start timer in background service
      await PomodoroBackgroundService.startTimer(
        sessionType: sessionType,
        durationMinutes: duration,
        taskDescription: event.taskDescription,
      );

      // Update settings in background service
      await PomodoroBackgroundService.updateSettings(_settings);

      emit(PomodoroRunning(
        currentSession: _currentSession!,
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
      ));

      // Save state
      await _saveState();
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
      HapticService.timerPause();

      // Play pause sound
      await _audioService.playPomodoroSound(PomodoroSoundType.sessionPause);

      // Pause timer in background service
      await PomodoroBackgroundService.pauseTimer();

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

      // Play resume sound
      await _audioService.playPomodoroSound(PomodoroSoundType.sessionResume);

      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.active,
        resumedAt: [..._currentSession!.resumedAt, DateTime.now()],
      );

      // Resume timer in background service
      await PomodoroBackgroundService.resumeTimer();

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

    // Stop timer in background service
    await PomodoroBackgroundService.stopTimer();

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
        HapticService.pomodoroComplete();
      }

      // Play completion sound based on session type (in-app sound)
      // This works when app is in foreground
      if (_currentSession!.type == PomodoroType.work) {
        await _audioService
            .playPomodoroSound(PomodoroSoundType.sessionComplete);
      } else if (_currentSession!.type == PomodoroType.longBreak) {
        await _audioService
            .playPomodoroSound(PomodoroSoundType.finalBreakComplete);
      } else {
        await _audioService.playPomodoroSound(PomodoroSoundType.breakComplete);
      }

      // Show completion notification with custom sound for background alerts
      // This ensures sound plays even when app is backgrounded
      if (_settings.enableNotifications) {
        final sessionTypeName = _currentSession!.type == PomodoroType.work
            ? 'Work'
            : _currentSession!.type == PomodoroType.longBreak
                ? 'Long Break'
                : 'Break';

        final message = _currentSession!.type == PomodoroType.work
            ? 'Great job! Time for a break.'
            : 'Break time is over. Ready to focus?';

        // Determine next session type
        final nextSessionType = _currentSession!.type == PomodoroType.work
            ? (_completedWorkSessions % _settings.sessionsUntilLongBreak ==
                    _settings.sessionsUntilLongBreak - 1
                ? 'Long Break'
                : 'Short Break')
            : 'Work Session';

        print(
            'PomodoroBloc: Showing session completion notification with sound for background playback');

        // Critical: This notification will play custom sounds even when app is backgrounded
        await _notificationService.showSessionCompletionNotification(
          sessionType: sessionTypeName,
          message: message,
          nextSessionType: nextSessionType,
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
    try {
      // Prevent multiple simultaneous skip break requests
      if (state is! PomodoroRunning && state is! PomodoroPaused) {
        print('PomodoroBloc: Skip break requested but no valid active session');
        return;
      }

      final currentSession = (state is PomodoroRunning)
          ? (state as PomodoroRunning).currentSession
          : (state as PomodoroPaused).currentSession;

      // Only allow skipping breaks
      if (currentSession.type != PomodoroType.shortBreak &&
          currentSession.type != PomodoroType.longBreak) {
        print(
            'PomodoroBloc: Skip break requested but current session is not a break: ${currentSession.type.name}');
        return;
      }

      print(
          'PomodoroBloc: Skipping ${currentSession.type.name} session (ID: ${currentSession.id})');

      // Provide haptic feedback for skip action
      HapticService.buttonTap();

      // Stop current timer immediately and cancel notification
      _timer?.cancel();
      await _cancelNotification();
      print('PomodoroBloc: Cancelled timer and notification for skip break');

      // Mark current break as completed and add to sessions
      final completedBreak = currentSession.copyWith(
        status: SessionStatus.completed,
        endTime: DateTime.now(),
        timeSpentSeconds:
            currentSession.totalDurationSeconds, // Mark as fully completed
      );
      _sessions.add(completedBreak);
      print(
          'PomodoroBloc: Marked break as completed and added to sessions history');

      // Generate unique ID for new work session
      final sessionId = const Uuid().v4();

      // Create and start next work session
      final nextSession = PomodoroSession(
        id: sessionId,
        type: PomodoroType.work,
        durationMinutes: _settings.workDurationMinutes,
        startTime: DateTime.now(),
        taskDescription: currentSession.taskDescription,
        status: SessionStatus.active,
      );

      // Update current session reference
      _currentSession = nextSession;
      print(
          'PomodoroBloc: Created new work session (ID: $sessionId, Duration: ${_settings.workDurationMinutes}min)');

      // Start timer for new work session
      await PomodoroBackgroundService.startTimer(
        sessionType: PomodoroType.work,
        durationMinutes: _settings.workDurationMinutes,
        taskDescription: currentSession.taskDescription,
      );

      // Update settings in background service
      await PomodoroBackgroundService.updateSettings(_settings);

      // Play work start sound
      await _audioService.playPomodoroSound(PomodoroSoundType.sessionStart);

      // Emit new running state
      emit(PomodoroRunning(
        currentSession: nextSession,
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
      ));
      print('PomodoroBloc: Emitted PomodoroRunning state for new work session');

      // Save state to ensure persistence
      await _saveState();

      // Update notification for new work session
      await _updateNotification();
      print(
          'PomodoroBloc: Skip break completed successfully - now running ${nextSession.durationMinutes}min work session');
    } catch (e, stackTrace) {
      print('PomodoroBloc: Error during skip break: $e');
      print('Stack trace: $stackTrace');
      emit(PomodoroError('Failed to skip break: $e'));
    }
  }

  Future<void> _onSettingsUpdated(
    PomodoroSettingsUpdated event,
    Emitter<PomodoroState> emit,
  ) async {
    _settings = event.settings as PomodoroSettings;

    // Update audio service settings
    _audioService.setEnabled(_settings.enableSounds);
    _audioService.setVolume(_settings.soundVolume);

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
      print('Loading Pomodoro history...');
      final today = event.date ?? DateTime.now();
      print('Sessions count: ${_sessions.length}');

      final todayStats = PomodoroStatistics.fromSessions(today, _sessions);
      print('Today stats calculated');

      // Generate weekly stats
      final weeklyStats = <PomodoroStatistics>[];
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dayStats = PomodoroStatistics.fromSessions(date, _sessions);
        weeklyStats.add(dayStats);
      }
      print('Weekly stats calculated: ${weeklyStats.length} days');

      // If currently running or paused, update the current state with statistics data
      // instead of replacing it with PomodoroHistoryLoaded
      if (state is PomodoroRunning) {
        final currentState = state as PomodoroRunning;
        emit(PomodoroRunning(
          currentSession: currentState.currentSession,
          settings: currentState.settings,
          completedWorkSessions: currentState.completedWorkSessions,
          isLongBreakNext: currentState.isLongBreakNext,
          todayStats: todayStats,
          weeklyStats: weeklyStats,
          sessions: _sessions,
        ));
        print('Updated PomodoroRunning state with statistics');
      } else if (state is PomodoroPaused) {
        final currentState = state as PomodoroPaused;
        emit(PomodoroPaused(
          currentSession: currentState.currentSession,
          settings: currentState.settings,
          completedWorkSessions: currentState.completedWorkSessions,
          isLongBreakNext: currentState.isLongBreakNext,
          todayStats: todayStats,
          weeklyStats: weeklyStats,
          sessions: _sessions,
        ));
        print('Updated PomodoroPaused state with statistics');
      } else {
        // For other states, emit the normal PomodoroHistoryLoaded state
        emit(PomodoroHistoryLoaded(
          sessions: _sessions,
          todayStats: todayStats,
          weeklyStats: weeklyStats,
          settings: _settings,
        ));
        print('PomodoroHistoryLoaded state emitted');
      }
    } catch (e, stackTrace) {
      print('Error loading history: $e');
      print('Stack trace: $stackTrace');
      emit(PomodoroError('Failed to load history: $e'));
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Sync with background service by reloading state
      add(const PomodoroTimeSyncRequested());
    });
  }

  PomodoroType _getNextSessionType() {
    // Since we removed persistence, always start with work
    // Simple logic: work sessions get breaks, breaks get work
    if (_completedWorkSessions > 0 &&
        _completedWorkSessions % _settings.sessionsUntilLongBreak == 0) {
      return PomodoroType.longBreak;
    }

    // For now, since we have no persistence, always start with work
    // Could be enhanced later with simple alternating logic
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

  // Sync timer with actual elapsed time (fixes background timer issues)
  Future<void> _onTimeSyncRequested(
    PomodoroTimeSyncRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    // Reload state from shared preferences to sync with background service
    await _loadState();

    // Emit current state based on loaded session
    if (_currentSession != null) {
      if (_currentSession!.status == SessionStatus.paused) {
        emit(PomodoroPaused(
          currentSession: _currentSession!,
          settings: _settings,
          completedWorkSessions: _completedWorkSessions,
          isLongBreakNext: _isLongBreakNext(),
        ));
      } else if (_currentSession!.status == SessionStatus.active) {
        if (_currentSession!.remainingSeconds <= 0) {
          add(const PomodoroCompleted());
        } else {
          emit(PomodoroRunning(
            currentSession: _currentSession!,
            settings: _settings,
            completedWorkSessions: _completedWorkSessions,
            isLongBreakNext: _isLongBreakNext(),
          ));
        }
      }
    } else {
      emit(PomodoroReady(
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
      ));
    }
  }

  // Reset all pomodoro state to clean slate
  Future<void> _onResetRequested(
    PomodoroResetRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    try {
      print('PomodoroBloc: Resetting all Pomodoro state...');

      // Provide haptic feedback for reset action
      HapticService.buttonTap();

      // Stop any running timer
      _timer?.cancel();
      print('PomodoroBloc: Timer cancelled');

      // Cancel any notifications
      await _cancelNotification();
      print('PomodoroBloc: Notifications cancelled');

      // If there's a current session, mark it as cancelled and add to history
      if (_currentSession != null) {
        final cancelledSession = _currentSession!.copyWith(
          status: SessionStatus.cancelled,
          endTime: DateTime.now(),
        );
        _sessions.add(cancelledSession);
        print(
            'PomodoroBloc: Current session marked as cancelled and added to history');
      }

      // Clear current session
      _currentSession = null;

      // Reset work sessions count to 0 (fresh start)
      _completedWorkSessions = 0;

      // No persistence - just reset in memory
      print('PomodoroBloc: Reset completed - no persistence');

      // Emit ready state (clean slate)
      emit(PomodoroReady(
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: false, // Reset to false for fresh start
      ));

      print('PomodoroBloc: Reset completed successfully - back to ready state');
    } catch (e, stackTrace) {
      print('PomodoroBloc: Error during reset: $e');
      print('Stack trace: $stackTrace');
      emit(PomodoroError('Failed to reset Pomodoro: $e'));
    }
  }
}
