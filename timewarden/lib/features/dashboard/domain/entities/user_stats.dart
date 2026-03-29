import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats extends Equatable {
  final String userId;
  final int perfectDays;
  final List<DateTime> perfectDayDates; // List of actual perfect day dates
  final int totalHabitsCreated;
  final int totalPomodoroSessions;
  final int totalJournalEntries;
  final DateTime lastUpdated;
  final DateTime createdAt;

  // Points system
  final double totalPointsToday;
  final DateTime lastPointsResetDate;
  final String? pointRewardDescription;

  const UserStats({
    required this.userId,
    this.perfectDays = 0,
    this.perfectDayDates = const [],
    this.totalHabitsCreated = 0,
    this.totalPomodoroSessions = 0,
    this.totalJournalEntries = 0,
    required this.lastUpdated,
    required this.createdAt,
    this.totalPointsToday = 0.0,
    DateTime? lastPointsResetDate,
    this.pointRewardDescription,
  }) : lastPointsResetDate = lastPointsResetDate ?? createdAt;

  UserStats copyWith({
    String? userId,
    int? perfectDays,
    List<DateTime>? perfectDayDates,
    int? totalHabitsCreated,
    int? totalPomodoroSessions,
    int? totalJournalEntries,
    DateTime? lastUpdated,
    DateTime? createdAt,
    double? totalPointsToday,
    DateTime? lastPointsResetDate,
    String? pointRewardDescription,
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
      totalPointsToday: totalPointsToday ?? this.totalPointsToday,
      lastPointsResetDate: lastPointsResetDate ?? this.lastPointsResetDate,
      pointRewardDescription:
          pointRewardDescription ?? this.pointRewardDescription,
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
      'totalPointsToday': totalPointsToday,
      'lastPointsResetDate': lastPointsResetDate.toIso8601String(),
      'pointRewardDescription': pointRewardDescription,
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['userId'] as String,
      perfectDays: json['perfectDays'] as int? ?? 0,
      perfectDayDates: (json['perfectDayDates'] as List<dynamic>?)?.map((d) {
            if (d is Timestamp) {
              return d.toDate();
            } else if (d is String) {
              return DateTime.parse(d);
            } else {
              return DateTime.now();
            }
          }).toList() ??
          [],
      totalHabitsCreated: json['totalHabitsCreated'] as int? ?? 0,
      totalPomodoroSessions: json['totalPomodoroSessions'] as int? ?? 0,
      totalJournalEntries: json['totalJournalEntries'] as int? ?? 0,
      lastUpdated: _parseDateTime(json['lastUpdated']),
      createdAt: _parseDateTime(json['createdAt']),
      totalPointsToday: (json['totalPointsToday'] as num?)?.toDouble() ?? 0.0,
      lastPointsResetDate: json['lastPointsResetDate'] != null
          ? _parseDateTime(json['lastPointsResetDate'])
          : _parseDateTime(json['createdAt']),
      pointRewardDescription: json['pointRewardDescription'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      return DateTime.now();
    }
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
        totalPointsToday,
        lastPointsResetDate,
        pointRewardDescription,
      ];
}
