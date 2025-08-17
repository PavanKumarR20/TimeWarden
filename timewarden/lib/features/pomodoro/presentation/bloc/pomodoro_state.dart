import 'package:equatable/equatable.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/entities/pomodoro_settings.dart';
import '../../domain/entities/pomodoro_statistics.dart';

abstract class PomodoroState extends Equatable {
  const PomodoroState();

  @override
  List<Object?> get props => [];
}

class PomodoroInitial extends PomodoroState {
  const PomodoroInitial();
}

class PomodoroLoading extends PomodoroState {
  const PomodoroLoading();
}

class PomodoroReady extends PomodoroState {
  final PomodoroSettings settings;
  final int completedWorkSessions;
  final bool isLongBreakNext;

  const PomodoroReady({
    required this.settings,
    this.completedWorkSessions = 0,
    this.isLongBreakNext = false,
  });

  @override
  List<Object?> get props => [settings, completedWorkSessions, isLongBreakNext];
}

class PomodoroRunning extends PomodoroState {
  final PomodoroSession currentSession;
  final PomodoroSettings settings;
  final int completedWorkSessions;
  final bool isLongBreakNext;

  const PomodoroRunning({
    required this.currentSession,
    required this.settings,
    this.completedWorkSessions = 0,
    this.isLongBreakNext = false,
  });

  @override
  List<Object?> get props => [
        currentSession,
        settings,
        completedWorkSessions,
        isLongBreakNext,
      ];
}

class PomodoroPaused extends PomodoroState {
  final PomodoroSession currentSession;
  final PomodoroSettings settings;
  final int completedWorkSessions;
  final bool isLongBreakNext;

  const PomodoroPaused({
    required this.currentSession,
    required this.settings,
    this.completedWorkSessions = 0,
    this.isLongBreakNext = false,
  });

  @override
  List<Object?> get props => [
        currentSession,
        settings,
        completedWorkSessions,
        isLongBreakNext,
      ];
}

class PomodoroSessionCompleted extends PomodoroState {
  final PomodoroSession completedSession;
  final PomodoroSettings settings;
  final int completedWorkSessions;
  final bool isLongBreakNext;
  final PomodoroType nextSessionType;

  const PomodoroSessionCompleted({
    required this.completedSession,
    required this.settings,
    required this.completedWorkSessions,
    required this.isLongBreakNext,
    required this.nextSessionType,
  });

  @override
  List<Object?> get props => [
        completedSession,
        settings,
        completedWorkSessions,
        isLongBreakNext,
        nextSessionType,
      ];
}

class PomodoroHistoryLoaded extends PomodoroState {
  final List<PomodoroSession> sessions;
  final PomodoroStatistics todayStats;
  final List<PomodoroStatistics> weeklyStats;
  final PomodoroSettings settings;

  const PomodoroHistoryLoaded({
    required this.sessions,
    required this.todayStats,
    required this.weeklyStats,
    required this.settings,
  });

  @override
  List<Object?> get props => [sessions, todayStats, weeklyStats, settings];
}

class PomodoroError extends PomodoroState {
  final String message;

  const PomodoroError(this.message);

  @override
  List<Object?> get props => [message];
}
