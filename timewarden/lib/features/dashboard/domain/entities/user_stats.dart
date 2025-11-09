import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  final String userId;
  final int perfectDays;
  final List<DateTime> perfectDayDates; // List of actual perfect day dates
  final int totalHabitsCreated;
  final int totalPomodoroSessions;
  final int totalJournalEntries;
  final DateTime lastUpdated;
  final DateTime createdAt;

  const UserStats({
    required this.userId,
    this.perfectDays = 0,
    this.perfectDayDates = const [],
    this.totalHabitsCreated = 0,
    this.totalPomodoroSessions = 0,
    this.totalJournalEntries = 0,
    required this.lastUpdated,
    required this.createdAt,
  });

  UserStats copyWith({
    String? userId,
    int? perfectDays,
    List<DateTime>? perfectDayDates,
    int? totalHabitsCreated,
    int? totalPomodoroSessions,
    int? totalJournalEntries,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      perfectDays: perfectDays ?? this.perfectDays,
      perfectDayDates: perfectDayDates ?? this.perfectDayDates,
      totalHabitsCreated: totalHabitsCreated ?? this.totalHabitsCreated,
      totalPomodoroSessions:
          totalPomodoroSessions ?? this.totalPomodoroSessions,
      totalJournalEntries: totalJournalEntries ?? this.totalJournalEntries,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'perfectDays': perfectDays,
      'perfectDayDates':
          perfectDayDates.map((d) => d.toIso8601String()).toList(),
      'totalHabitsCreated': totalHabitsCreated,
      'totalPomodoroSessions': totalPomodoroSessions,
      'totalJournalEntries': totalJournalEntries,
      'lastUpdated': lastUpdated.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['userId'] as String,
      perfectDays: json['perfectDays'] as int? ?? 0,
      perfectDayDates: (json['perfectDayDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
      totalHabitsCreated: json['totalHabitsCreated'] as int? ?? 0,
      totalPomodoroSessions: json['totalPomodoroSessions'] as int? ?? 0,
      totalJournalEntries: json['totalJournalEntries'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        perfectDays,
        perfectDayDates,
        totalHabitsCreated,
        totalPomodoroSessions,
        totalJournalEntries,
        lastUpdated,
        createdAt,
      ];
}
