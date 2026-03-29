import 'package:equatable/equatable.dart';

enum PomodoroType {
  work,
  shortBreak,
  longBreak,
}

enum SessionStatus {
  pending,
  active,
  paused,
  completed,
  cancelled,
}

class PomodoroSession extends Equatable {
  final String id;
  final PomodoroType type;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionStatus status;
  final int timeSpentSeconds; // Actual time spent (for paused sessions)
  final String? taskDescription;
  final List<DateTime> pausedAt;
  final List<DateTime> resumedAt;

  const PomodoroSession({
    required this.id,
    required this.type,
    required this.durationMinutes,
    required this.startTime,
    this.endTime,
    this.status = SessionStatus.pending,
    this.timeSpentSeconds = 0,
    this.taskDescription,
    this.pausedAt = const [],
    this.resumedAt = const [],
  });

  bool get isCompleted => status == SessionStatus.completed;
  bool get isActive => status == SessionStatus.active;
  bool get isPaused => status == SessionStatus.paused;
  bool get isCancelled => status == SessionStatus.cancelled;

  int get totalDurationSeconds => durationMinutes * 60;
  int get remainingSeconds => totalDurationSeconds - timeSpentSeconds;

  double get progressPercentage {
    if (totalDurationSeconds == 0) return 0.0;
    return (timeSpentSeconds / totalDurationSeconds).clamp(0.0, 1.0);
  }

  Duration get elapsedTime => Duration(seconds: timeSpentSeconds);
  Duration get remainingTime => Duration(seconds: remainingSeconds);

  String get displayType {
    switch (type) {
      case PomodoroType.work:
        return 'Focus';
      case PomodoroType.shortBreak:
        return 'Short Break';
      case PomodoroType.longBreak:
        return 'Long Break';
    }
  }

  PomodoroSession copyWith({
    String? id,
    PomodoroType? type,
    int? durationMinutes,
    DateTime? startTime,
    DateTime? endTime,
    SessionStatus? status,
    int? timeSpentSeconds,
    String? taskDescription,
    List<DateTime>? pausedAt,
    List<DateTime>? resumedAt,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      taskDescription: taskDescription ?? this.taskDescription,
      pausedAt: pausedAt ?? this.pausedAt,
      resumedAt: resumedAt ?? this.resumedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'durationMinutes': durationMinutes,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.name,
      'timeSpentSeconds': timeSpentSeconds,
      'taskDescription': taskDescription,
      'pausedAt': pausedAt.map((e) => e.toIso8601String()).toList(),
      'resumedAt': resumedAt.map((e) => e.toIso8601String()).toList(),
    };
  }

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'] as String,
      type: PomodoroType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PomodoroType.work,
      ),
      durationMinutes: json['durationMinutes'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.pending,
      ),
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      taskDescription: json['taskDescription'] as String?,
      pausedAt: (json['pausedAt'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
      resumedAt: (json['resumedAt'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        durationMinutes,
        startTime,
        endTime,
        status,
        timeSpentSeconds,
        taskDescription,
        pausedAt,
        resumedAt,
      ];
}
