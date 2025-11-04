import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:uuid/uuid.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/entities/pomodoro_settings.dart';
import '../../domain/entities/pomodoro_statistics.dart';
import '../../domain/repositories/pomodoro_repository.dart';
import '../../../dashboard/data/repositories/user_stats_repository_impl.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/haptic_service.dart';
import 'pomodoro_event.dart';
import 'pomodoro_state.dart';

class PomodoroBloc extends Bloc<PomodoroEvent, PomodoroState> {
  Timer? _mainTimer; // Single timer for session management
  PomodoroSession? _currentSession;
  PomodoroSettings _settings = const PomodoroSettings();
  final List<PomodoroSession> _sessions = [];
  int _completedWorkSessions = 0;
  bool _hasBeenInitialized = false;

  // Simple audio player - just like Timer page
  final AudioPlayer _audioPlayer = AudioPlayer();

  final PomodoroRepository _repository;
  late final UserStatsRepositoryImpl _statsRepository;

  PomodoroBloc(this._repository) : super(const PomodoroInitial()) {
    _statsRepository = UserStatsRepositoryImpl(FirebaseService());
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
  }

  // Simple helper to play sounds - like Timer page
  Future<void> _playSound(String soundFile) async {
    try {
      await _audioPlayer.play(AssetSource('audio/$soundFile'));
    } catch (e) {
      // Silent catch - sound will not play if there's an error
    }
  }

  // Persistence methods
  Future<void> _saveState() async {
    // No persistence - removed to keep simple Pomodoro functionality
  }

  Future<void> _loadState() async {
    // Load sessions from Firestore
    try {
      final sessions = await _repository.getSessions();
      _sessions.clear();
      _sessions.addAll(sessions);

      // Count completed work sessions for today
      final today = DateTime.now();
      final todaySessions = sessions
          .where((session) =>
              session.type == PomodoroType.work &&
              session.status == SessionStatus.completed &&
              _isSameDay(session.startTime, today))
          .toList();
      _completedWorkSessions = todaySessions.length;

      print(
          'PomodoroBloc: Loaded ${sessions.length} sessions, $_completedWorkSessions completed work sessions today');
    } catch (e) {
      print('PomodoroBloc: Error loading sessions: $e');
      _sessions.clear();
      _completedWorkSessions = 0;
    }

    _currentSession = null;
  }

  void _startMainTimer() {
    _mainTimer?.cancel();
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession != null) {
        final elapsed = DateTime.now().difference(_currentSession!.startTime);
        add(PomodoroTick(elapsed.inSeconds));
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Future<void> close() async {
    _mainTimer?.cancel();
    _audioPlayer.dispose();
    print('PomodoroBloc: Closing - timers cancelled');
    return super.close();
  }

  Future<void> _onLoadRequested(
    PomodoroLoadRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    // If already initialized and has an active session, don't reload
    if (_hasBeenInitialized && _currentSession != null) {
      print(
          'PomodoroBloc: Already initialized with active session - skipping reload');
      // Emit current state based on session status
      if (_currentSession!.status == SessionStatus.paused) {
        emit(PomodoroPaused(
          currentSession: _currentSession!,
          settings: _settings,
          completedWorkSessions: _completedWorkSessions,
          isLongBreakNext: _isLongBreakNext(),
        ));
      } else if (_currentSession!.status == SessionStatus.active) {
        emit(PomodoroRunning(
          currentSession: _currentSession!,
          settings: _settings,
          completedWorkSessions: _completedWorkSessions,
          isLongBreakNext: _isLongBreakNext(),
        ));
      }
      return;
    }

    emit(const PomodoroLoading());

    try {
      // Load saved state
      await _loadState();

      _hasBeenInitialized = true;

      // Always start fresh after clearing old data - don't sync with old sessions
      emit(PomodoroReady(
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
      ));

      print('PomodoroBloc: App started fresh - ready for new sessions');
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
      print(
          'PomodoroBloc: Session created successfully - ID: ${_currentSession!.id}');

      // Play appropriate start sound
      try {
        if (sessionType == PomodoroType.work) {
          print('PomodoroBloc: Playing work session start sound');
          await _playSound('work_start.mp3');
        } else {
          print('PomodoroBloc: Playing break session start sound');
          await _playSound('break_start.mp3');
        }
      } catch (e) {
        print('PomodoroBloc: Error playing sound: $e');
        // Continue execution even if sound fails
      }

      // Skip background service for now - just run local timer
      // This simplifies the implementation and avoids notification conflicts
      print('PomodoroBloc: Starting local timer (background service disabled)');
      _startMainTimer();

      print('PomodoroBloc: Local timer started successfully');

      // Verify _currentSession is still not null before emitting
      if (_currentSession == null) {
        print(
            'PomodoroBloc: ERROR - _currentSession became null after background service calls');
        throw Exception('Current session became null unexpectedly');
      }

      print(
          'PomodoroBloc: Emitting PomodoroRunning state with session ID: ${_currentSession!.id}');
      emit(PomodoroRunning(
        currentSession: _currentSession!,
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
      ));
      print('PomodoroBloc: Successfully emitted PomodoroRunning state');

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
      HapticService.buttonTap();

      // No pause sound - keep it simple

      // Pause the main timer
      _mainTimer?.cancel();
      print('PomodoroBloc: Main timer paused');

      // Update session status locally
      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.paused,
        pausedAt: [..._currentSession!.pausedAt, DateTime.now()],
      );

      // Emit paused state immediately
      emit(PomodoroPaused(
        currentSession: _currentSession!,
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
      ));

      // Disable notifications to keep it simple
      // await _updateNotification();

      print('PomodoroBloc: Timer paused successfully');
    }
  }

  Future<void> _onResumeRequested(
    PomodoroResumeRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    if (_currentSession != null) {
      HapticService.buttonTap();

      // No resume sound - keep it simple

      // Update session status locally
      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.active,
        resumedAt: [..._currentSession!.resumedAt, DateTime.now()],
      );

      // Emit running state immediately
      emit(PomodoroRunning(
        currentSession: _currentSession!,
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: _isLongBreakNext(),
      ));

      // Resume the main timer
      _startMainTimer();

      // Disable notifications to keep it simple
      // await _updateNotification();

      print('PomodoroBloc: Timer resumed successfully');
    }
  }

  Future<void> _onStopRequested(
    PomodoroStopRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    HapticService.buttonTap();

    // Stop the main timer
    _mainTimer?.cancel();
    print('PomodoroBloc: Main timer stopped');

    // Update session status locally
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.cancelled,
        endTime: DateTime.now(),
      );
      _sessions.add(_currentSession!);

      // Save cancelled session to repository
      try {
        await _repository.saveSession(_currentSession!);
        print('PomodoroBloc: Saved cancelled session to Firestore');
      } catch (e) {
        print('PomodoroBloc: Error saving cancelled session to Firestore: $e');
      }
    }

    _currentSession = null;

    // Emit ready state immediately
    emit(PomodoroReady(
      settings: _settings,
      completedWorkSessions: _completedWorkSessions,
      isLongBreakNext: _isLongBreakNext(),
    ));

    // No notifications or background service - keep it simple
    print('PomodoroBloc: Timer stopped successfully');
  }

  Future<void> _onTick(
    PomodoroTick event,
    Emitter<PomodoroState> emit,
  ) async {
    if (_currentSession != null) {
      // Calculate actual elapsed time accounting for pauses
      final now = DateTime.now();
      final totalElapsed = now.difference(_currentSession!.startTime).inSeconds;

      // Calculate paused time
      int pausedSeconds = 0;
      for (int i = 0; i < _currentSession!.pausedAt.length; i++) {
        final pauseStart = _currentSession!.pausedAt[i];
        final resumeTime = i < _currentSession!.resumedAt.length
            ? _currentSession!.resumedAt[i]
            : (_currentSession!.status == SessionStatus.paused
                ? now
                : pauseStart);
        pausedSeconds += resumeTime.difference(pauseStart).inSeconds;
      }

      final activeSeconds = totalElapsed - pausedSeconds;

      _currentSession = _currentSession!.copyWith(
        timeSpentSeconds: activeSeconds,
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

        // Disable notification updates to avoid conflicts
        // await _updateNotification();
      }
    }
  }

  Future<void> _onCompleted(
    PomodoroCompleted event,
    Emitter<PomodoroState> emit,
  ) async {
    _mainTimer?.cancel();

    if (_currentSession != null) {
      print(
          'PomodoroBloc: Session completed - Type: ${_currentSession!.type.name}');

      // ALWAYS provide completion feedback (vibration)
      HapticService.pomodoroComplete();

      // ALWAYS play completion sound (like Timer page does)
      try {
        print('PomodoroBloc: Playing completion sound...');
        if (_currentSession!.type == PomodoroType.work) {
          await _playSound('session_complete.mp3');
        } else if (_currentSession!.type == PomodoroType.longBreak) {
          await _playSound('session_complete.mp3');
        } else {
          await _playSound('break_complete.mp3');
        }
        print('PomodoroBloc: Completion sound played successfully');
      } catch (e) {
        print('PomodoroBloc: Error playing completion sound: $e');
      }

      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.completed,
        endTime: DateTime.now(),
        timeSpentSeconds: _currentSession!.totalDurationSeconds,
      );

      _sessions.add(_currentSession!);

      // Save completed session to repository
      try {
        await _repository.saveSession(_currentSession!);
        print('PomodoroBloc: Saved completed session to Firestore');

        // Increment Pomodoro stats counter
        final userId = FirebaseService().currentUserId;
        if (userId != null) {
          await _statsRepository.incrementPomodoroSessions(userId);
          print('PomodoroBloc: Incremented Pomodoro stats counter');
        }
      } catch (e) {
        print('PomodoroBloc: Error saving session to Firestore: $e');
        // Don't emit error here, just log it - session is still tracked locally
      }

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

    // No notifications - keep it simple like Timer page
    print(
        'PomodoroBloc: Session completed successfully - no background service');
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

      // Stop current timer immediately
      _mainTimer?.cancel();
      print('PomodoroBloc: Cancelled timer for skip break');

      // Mark current break as completed and add to sessions
      final completedBreak = currentSession.copyWith(
        status: SessionStatus.completed,
        endTime: DateTime.now(),
        timeSpentSeconds:
            currentSession.totalDurationSeconds, // Mark as fully completed
      );
      _sessions.add(completedBreak);

      // Save skipped break session to repository
      try {
        await _repository.saveSession(completedBreak);
        print('PomodoroBloc: Saved skipped break session to Firestore');
      } catch (e) {
        print(
            'PomodoroBloc: Error saving skipped break session to Firestore: $e');
      }
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

      // Start local timer for new work session
      _startMainTimer();

      // Play work start sound
      await _playSound('work_start.mp3');

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

    // Settings updated - no audio service needed

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

      // Refresh sessions from repository to get latest data
      try {
        final latestSessions = await _repository.getSessions();
        _sessions.clear();
        _sessions.addAll(latestSessions);
        print(
            'Refreshed sessions from repository: ${latestSessions.length} sessions');
      } catch (e) {
        print('Error refreshing sessions from repository: $e');
        // Continue with existing sessions if repository fails
      }

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
    // Disabled - using direct timer instead of background service sync
    print('PomodoroBloc: Sync timer disabled - using direct timer approach');
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

  // Notifications disabled - simplified implementation
  Future<void> _updateNotification() async {
    // Disabled
  }

  Future<void> _cancelNotification() async {
    // Disabled
  }

  // Sync timer - no background service anymore
  Future<void> _onTimeSyncRequested(
    PomodoroTimeSyncRequested event,
    Emitter<PomodoroState> emit,
  ) async {
    print(
        'PomodoroBloc: Sync requested but not implemented - no background service');
    // No background service - just emit current state
    if (_currentSession != null) {
      if (_currentSession!.status == SessionStatus.paused) {
        emit(PomodoroPaused(
          currentSession: _currentSession!,
          settings: _settings,
          completedWorkSessions: _completedWorkSessions,
          isLongBreakNext: _isLongBreakNext(),
        ));
      } else if (_currentSession!.status == SessionStatus.active) {
        emit(PomodoroRunning(
          currentSession: _currentSession!,
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
      _mainTimer?.cancel();
      print('PomodoroBloc: All timers cancelled');

      // Update local state first - if there's a current session, mark it as cancelled
      if (_currentSession != null) {
        final cancelledSession = _currentSession!.copyWith(
          status: SessionStatus.cancelled,
          endTime: DateTime.now(),
        );
        _sessions.add(cancelledSession);

        // Save cancelled session to repository
        try {
          await _repository.saveSession(cancelledSession);
          print(
              'PomodoroBloc: Saved cancelled session to Firestore (from reset)');
        } catch (e) {
          print(
              'PomodoroBloc: Error saving cancelled session to Firestore (from reset): $e');
        }

        print(
            'PomodoroBloc: Current session marked as cancelled and added to history');
      }

      // Clear current session
      _currentSession = null;

      // Reset work sessions count to 0 (fresh start)
      _completedWorkSessions = 0;

      // Emit ready state immediately
      emit(PomodoroReady(
        settings: _settings,
        completedWorkSessions: _completedWorkSessions,
        isLongBreakNext: false, // Reset to false for fresh start
      ));

      // No notifications or background service - simplified
      print('PomodoroBloc: Reset completed - no persistence');

      print('PomodoroBloc: Reset completed successfully - back to ready state');
    } catch (e, stackTrace) {
      print('PomodoroBloc: Error during reset: $e');
      print('Stack trace: $stackTrace');
      emit(PomodoroError('Failed to reset Pomodoro: $e'));
    }
  }

  /// Helper method to check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
