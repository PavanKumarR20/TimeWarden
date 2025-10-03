import 'package:equatable/equatable.dart';

class Goal extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? targetEndDate;
  final DateTime? actualEndDate;
  final bool isCompleted;
  final List<String> tags;

  const Goal({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.targetEndDate,
    this.actualEndDate,
    this.isCompleted = false,
    this.tags = const [],
  });

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? targetEndDate,
    DateTime? actualEndDate,
    bool? isCompleted,
    List<String>? tags,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      targetEndDate: targetEndDate ?? this.targetEndDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      isCompleted: isCompleted ?? this.isCompleted,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'targetEndDate': targetEndDate?.toIso8601String(),
      'actualEndDate': actualEndDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'tags': tags,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      targetEndDate: json['targetEndDate'] != null
          ? DateTime.parse(json['targetEndDate'] as String)
          : null,
      actualEndDate: json['actualEndDate'] != null
          ? DateTime.parse(json['actualEndDate'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  String get dateString {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final goalDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (goalDate == today) {
      return 'Today';
    } else if (goalDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String get timeString {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String? get targetDateString {
    if (targetEndDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(targetEndDate!.year, targetEndDate!.month, targetEndDate!.day);

    if (target == today) {
      return 'Today';
    } else if (target == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (target.isBefore(today)) {
      final difference = today.difference(target).inDays;
      return '$difference days overdue';
    } else {
      final difference = target.difference(today).inDays;
      return 'in $difference days';
    }
  }

  bool get isOverdue {
    if (targetEndDate == null || isCompleted) return false;
    return DateTime.now().isAfter(targetEndDate!);
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        createdAt,
        targetEndDate,
        actualEndDate,
        isCompleted,
        tags,
      ];
}
