import 'package:equatable/equatable.dart';
import '../../domain/entities/pomodoro_settings.dart';

abstract class PomodoroEvent extends Equatable {
  const PomodoroEvent();

  @override
  List<Object?> get props => [];
}

class PomodoroStartRequested extends PomodoroEvent {
  final String? taskDescription;

  const PomodoroStartRequested({this.taskDescription});

  @override
  List<Object?> get props => [taskDescription];
}

class PomodoroPauseRequested extends PomodoroEvent {
  const PomodoroPauseRequested();
}

class PomodoroResumeRequested extends PomodoroEvent {
  const PomodoroResumeRequested();
}

class PomodoroStopRequested extends PomodoroEvent {
  const PomodoroStopRequested();
}

class PomodoroCompleted extends PomodoroEvent {
  final bool playSound;

  const PomodoroCompleted({this.playSound = true});

  @override
  List<Object?> get props => [playSound];
}

class PomodoroTick extends PomodoroEvent {
  final int secondsElapsed;

  const PomodoroTick(this.secondsElapsed);

  @override
  List<Object?> get props => [secondsElapsed];
}

class PomodoroSettingsUpdated extends PomodoroEvent {
  final PomodoroSettings settings;

  const PomodoroSettingsUpdated(this.settings);

  @override
  List<Object?> get props => [settings];
}

class PomodoroNextSessionRequested extends PomodoroEvent {
  const PomodoroNextSessionRequested();
}

class PomodoroSkipBreakRequested extends PomodoroEvent {
  const PomodoroSkipBreakRequested();
}

class PomodoroLoadRequested extends PomodoroEvent {
  const PomodoroLoadRequested();
}

class PomodoroHistoryLoadRequested extends PomodoroEvent {
  final DateTime? date;

  const PomodoroHistoryLoadRequested({this.date});

  @override
  List<Object?> get props => [date];
}

class PomodoroTimeSyncRequested extends PomodoroEvent {
  const PomodoroTimeSyncRequested();
}

class PomodoroResetRequested extends PomodoroEvent {
  const PomodoroResetRequested();
}
