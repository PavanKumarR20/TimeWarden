import 'package:equatable/equatable.dart';
import 'pomodoro_session.dart';

class PomodoroStatistics extends Equatable {
  final DateTime date;
  final int completedWorkSessions;
  final int completedBreakSessions;
  final int totalWorkMinutes;
  final int totalBreakMinutes;
  final int cancelledSessions;
  final double averageSessionCompletion;
  final List<PomodoroSession> sessions;

  const PomodoroStatistics({
    required this.date,
    this.completedWorkSessions = 0,
    this.completedBreakSessions = 0,
    this.totalWorkMinutes = 0,
    this.totalBreakMinutes = 0,
    this.cancelledSessions = 0,
    this.averageSessionCompletion = 0.0,
    this.sessions = const [],
  });

  int get totalSessions => completedWorkSessions + completedBreakSessions;
  int get totalMinutes => totalWorkMinutes + totalBreakMinutes;

  Duration get totalFocusTime => Duration(minutes: totalWorkMinutes);
  Duration get totalBreakTime => Duration(minutes: totalBreakMinutes);
  Duration get totalTime => Duration(minutes: totalMinutes);

  double get focusEfficiency {
    if (totalMinutes == 0) return 0.0;
    return (totalWorkMinutes / totalMinutes * 100).clamp(0.0, 100.0);
  }

  double get completionRate {
    final totalStarted = totalSessions + cancelledSessions;
    if (totalStarted == 0) return 0.0;
    return (totalSessions / totalStarted * 100).clamp(0.0, 100.0);
  }

  static PomodoroStatistics fromSessions(
    DateTime date,
    List<PomodoroSession> sessions,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final dailySessions = sessions
        .where((session) =>
            session.startTime.isAfter(dayStart) &&
            session.startTime.isBefore(dayEnd))
        .toList();

    int completedWork = 0;
    int completedBreaks = 0;
    int totalWorkMinutes = 0;
    int totalBreakMinutes = 0;
    int cancelled = 0;
    double totalCompletion = 0.0;

    for (final session in dailySessions) {
      if (session.isCompleted) {
        if (session.type == PomodoroType.work) {
          completedWork++;
          totalWorkMinutes += session.durationMinutes;
        } else {
          completedBreaks++;
          totalBreakMinutes += session.durationMinutes;
        }
      } else if (session.isCancelled) {
        cancelled++;
      }

      totalCompletion += session.progressPercentage;
    }

    final averageCompletion =
        dailySessions.isEmpty ? 0.0 : totalCompletion / dailySessions.length;

    return PomodoroStatistics(
      date: date,
      completedWorkSessions: completedWork,
      completedBreakSessions: completedBreaks,
      totalWorkMinutes: totalWorkMinutes,
      totalBreakMinutes: totalBreakMinutes,
      cancelledSessions: cancelled,
      averageSessionCompletion: averageCompletion,
      sessions: dailySessions,
    );
  }

  PomodoroStatistics copyWith({
    DateTime? date,
    int? completedWorkSessions,
    int? completedBreakSessions,
    int? totalWorkMinutes,
    int? totalBreakMinutes,
    int? cancelledSessions,
    double? averageSessionCompletion,
    List<PomodoroSession>? sessions,
  }) {
    return PomodoroStatistics(
      date: date ?? this.date,
      completedWorkSessions:
          completedWorkSessions ?? this.completedWorkSessions,
      completedBreakSessions:
          completedBreakSessions ?? this.completedBreakSessions,
      totalWorkMinutes: totalWorkMinutes ?? this.totalWorkMinutes,
      totalBreakMinutes: totalBreakMinutes ?? this.totalBreakMinutes,
      cancelledSessions: cancelledSessions ?? this.cancelledSessions,
      averageSessionCompletion:
          averageSessionCompletion ?? this.averageSessionCompletion,
      sessions: sessions ?? this.sessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'completedWorkSessions': completedWorkSessions,
      'completedBreakSessions': completedBreakSessions,
      'totalWorkMinutes': totalWorkMinutes,
      'totalBreakMinutes': totalBreakMinutes,
      'cancelledSessions': cancelledSessions,
      'averageSessionCompletion': averageSessionCompletion,
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }

  factory PomodoroStatistics.fromJson(Map<String, dynamic> json) {
    return PomodoroStatistics(
      date: DateTime.parse(json['date'] as String),
      completedWorkSessions: json['completedWorkSessions'] as int? ?? 0,
      completedBreakSessions: json['completedBreakSessions'] as int? ?? 0,
      totalWorkMinutes: json['totalWorkMinutes'] as int? ?? 0,
      totalBreakMinutes: json['totalBreakMinutes'] as int? ?? 0,
      cancelledSessions: json['cancelledSessions'] as int? ?? 0,
      averageSessionCompletion:
          (json['averageSessionCompletion'] as num?)?.toDouble() ?? 0.0,
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((s) => PomodoroSession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        date,
        completedWorkSessions,
        completedBreakSessions,
        totalWorkMinutes,
        totalBreakMinutes,
        cancelledSessions,
        averageSessionCompletion,
        sessions,
      ];
}
