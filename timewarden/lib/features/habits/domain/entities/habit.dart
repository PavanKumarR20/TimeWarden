import 'package:equatable/equatable.dart';

enum HabitCategory {
  health,
  learning,
  productivity,
  fitness,
  mindfulness,
  social,
  creative,
  other,
}

enum HabitFrequencyType {
  daily, // Every day
  everyNDays, // Every N days
  timesPerWeek, // X times per week
  timesPerMonth, // X times per month
  timesInPeriod, // X times in Y days
}

class HabitFrequency {
  final HabitFrequencyType type;
  final int target; // Number (3, 10, etc.)
  final int? periodDays; // For "times in period" (14 days)

  const HabitFrequency({
    required this.type,
    required this.target,
    this.periodDays,
  });

  String get displayText {
    switch (type) {
      case HabitFrequencyType.daily:
        return 'Every day';
      case HabitFrequencyType.everyNDays:
        return 'Every $target days';
      case HabitFrequencyType.timesPerWeek:
        return '$target times per week';
      case HabitFrequencyType.timesPerMonth:
        return '$target times per month';
      case HabitFrequencyType.timesInPeriod:
        return '$target times in ${periodDays ?? 30} days';
    }
  }

  bool shouldShowOnDay(DateTime date) {
    // For now, show all habits every day (user decides when to complete)
    // Later we can implement more sophisticated scheduling
    return true;
  }

  // Create preset frequency options
  static List<HabitFrequency> get presets => [
        const HabitFrequency(type: HabitFrequencyType.daily, target: 1),
        const HabitFrequency(type: HabitFrequencyType.everyNDays, target: 2),
        const HabitFrequency(type: HabitFrequencyType.everyNDays, target: 3),
        const HabitFrequency(type: HabitFrequencyType.timesPerWeek, target: 3),
        const HabitFrequency(type: HabitFrequencyType.timesPerWeek, target: 5),
        const HabitFrequency(
            type: HabitFrequencyType.timesPerMonth, target: 10),
        const HabitFrequency(
            type: HabitFrequencyType.timesPerMonth, target: 15),
        const HabitFrequency(
            type: HabitFrequencyType.timesInPeriod, target: 3, periodDays: 7),
        const HabitFrequency(
            type: HabitFrequencyType.timesInPeriod, target: 5, periodDays: 14),
      ];
}

class Habit extends Equatable {
  final String id;
  final String name;
  final String? description;
  final HabitCategory category;
  final HabitFrequency frequency;
  final DateTime createdAt;
  final bool isActive;
  final int currentStreak;
  final int longestStreak;
  final List<DateTime> completedDates;
  final String? color; // Hex color code
  final String? icon; // Icon name or emoji

  const Habit({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.frequency,
    required this.createdAt,
    this.isActive = true,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completedDates = const [],
    this.color,
    this.icon,
  });

  bool get isCompletedToday {
    final today = DateTime.now();
    return completedDates.any((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);
  }

  bool isCompletedOnDate(DateTime date) {
    return completedDates.any((completedDate) =>
        completedDate.year == date.year &&
        completedDate.month == date.month &&
        completedDate.day == date.day);
  }

  bool shouldShowOnDate(DateTime date) {
    return frequency.shouldShowOnDay(date);
  }

  String get frequencyDisplayText {
    return frequency.displayText;
  }

  // Get completion status for a specific date
  bool isRequiredOnDate(DateTime date) {
    if (!isActive) return false;
    return frequency.shouldShowOnDay(date);
  }

  // Check if habit is completed for today and should be hidden when filtering
  bool get shouldHideWhenCompleted {
    return isCompletedToday && isRequiredOnDate(DateTime.now());
  }

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    HabitCategory? category,
    HabitFrequency? frequency,
    DateTime? createdAt,
    bool? isActive,
    int? currentStreak,
    int? longestStreak,
    List<DateTime>? completedDates,
    String? color,
    String? icon,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      completedDates: completedDates ?? this.completedDates,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'frequency': {
        'type': frequency.type.name,
        'target': frequency.target,
        'periodDays': frequency.periodDays,
      },
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'completedDates':
          completedDates.map((date) => date.toIso8601String()).toList(),
      'color': color,
      'icon': icon,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: HabitCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => HabitCategory.other,
      ),
      frequency: HabitFrequency(
        type: HabitFrequencyType.values.firstWhere(
          (e) => e.name == json['frequency']?['type'],
          orElse: () => HabitFrequencyType.daily,
        ),
        target: json['frequency']?['target'] as int? ?? 1,
        periodDays: json['frequency']?['periodDays'] as int?,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      completedDates: (json['completedDates'] as List<dynamic>?)
              ?.map((date) => DateTime.parse(date as String))
              .toList() ??
          [],
      color: json['color'] as String?,
      icon: json['icon'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        frequency,
        createdAt,
        isActive,
        currentStreak,
        longestStreak,
        completedDates,
        color,
        icon,
      ];
}
