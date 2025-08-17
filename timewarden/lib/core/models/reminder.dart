import 'package:equatable/equatable.dart';

class Reminder extends Equatable {
  final String id;
  final String habitId;
  final String title;
  final String? message;
  final DateTime scheduledTime;
  final bool isActive;
  final ReminderType type;

  const Reminder({
    required this.id,
    required this.habitId,
    required this.title,
    this.message,
    required this.scheduledTime,
    this.isActive = true,
    this.type = ReminderType.daily,
  });

  @override
  List<Object?> get props => [
        id,
        habitId,
        title,
        message,
        scheduledTime,
        isActive,
        type,
      ];

  Reminder copyWith({
    String? id,
    String? habitId,
    String? title,
    String? message,
    DateTime? scheduledTime,
    bool? isActive,
    ReminderType? type,
  }) {
    return Reminder(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'title': title,
      'message': message,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isActive': isActive,
      'type': type.name,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      title: json['title'] as String,
      message: json['message'] as String?,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      isActive: json['isActive'] as bool? ?? true,
      type: ReminderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReminderType.daily,
      ),
    );
  }
}

enum ReminderType {
  daily,
  weekly,
  custom,
}
