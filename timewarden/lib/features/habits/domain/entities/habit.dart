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
  // Description removed
  final String? notes; // Additional notes for detailed information
  final HabitCategory? category;
  final HabitFrequency frequency;
  final DateTime createdAt;
  final bool isActive;
  final int currentStreak;
  final int longestStreak;
  final List<DateTime> completedDates;
  final String? color; // Hex color code
  final String? icon; // Icon name or emoji

  // Reminder settings
  final bool reminderEnabled;
  final int? reminderHour; // 0-23
  final int? reminderMinute; // 0-59

  const Habit({
    required this.id,
    required this.name,
    this.notes,
    this.category,
    required this.frequency,
    required this.createdAt,
    this.isActive = true,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completedDates = const [],
    this.color,
    this.icon,
    this.reminderEnabled = false,
    this.reminderHour,
    this.reminderMinute,
  });

  bool get isCompletedToday {
    final today = DateTime.now();
    return completedDates.any((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);
  }

  /// Returns true if the habit is completed for the current period
  /// (day, week, or month depending on frequency type)
  bool get isCompletedForCurrentPeriod {
    final now = DateTime.now();

    switch (frequency.type) {
      case HabitFrequencyType.daily:
        return isCompletedToday;

      case HabitFrequencyType.everyNDays:
        return isCompletedToday;

      case HabitFrequencyType.timesPerWeek:
        // Check if completed this week
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final completionsThisWeek = completedDates
            .where((date) =>
                date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                date.isBefore(endOfWeek.add(const Duration(days: 1))))
            .length;
        return completionsThisWeek >= frequency.target;

      case HabitFrequencyType.timesPerMonth:
        // Check if completed this month
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1)
            .subtract(const Duration(days: 1));
        final completionsThisMonth = completedDates
            .where((date) =>
                date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                date.isBefore(endOfMonth.add(const Duration(days: 1))))
            .length;
        return completionsThisMonth >= frequency.target;

      case HabitFrequencyType.timesInPeriod:
        // Check if completed enough times in the specified period
        final periodStart =
            now.subtract(Duration(days: frequency.periodDays ?? 30));
        final completionsInPeriod = completedDates
            .where((date) =>
                date.isAfter(periodStart.subtract(const Duration(days: 1))) &&
                date.isBefore(now.add(const Duration(days: 1))))
            .length;
        return completionsInPeriod >= frequency.target;
    }
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

  // Check if habit is completed for current period but not today
  // Useful for showing "period completed" state in UI
  bool get isCompletedForPeriodButNotToday {
    return isCompletedForCurrentPeriod && !isCompletedToday;
  }

  Habit copyWith({
    String? id,
    String? name,
    String? notes,
    HabitCategory? category,
    HabitFrequency? frequency,
    DateTime? createdAt,
    bool? isActive,
    int? currentStreak,
    int? longestStreak,
    List<DateTime>? completedDates,
    String? color,
    String? icon,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      completedDates: completedDates ?? this.completedDates,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // 'description': removed
      'notes': notes,
      'category': category?.name,
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
      'reminderEnabled': reminderEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      notes: json['notes'] as String?,
      category: json['category'] != null
          ? HabitCategory.values.firstWhere(
              (e) => e.name == json['category'],
              orElse: () => HabitCategory.other,
            )
          : null,
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
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderHour: json['reminderHour'] as int?,
      reminderMinute: json['reminderMinute'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        notes,
        category,
        frequency,
        createdAt,
        isActive,
        currentStreak,
        longestStreak,
        completedDates,
        color,
        icon,
        reminderEnabled,
        reminderHour,
        reminderMinute,
      ];
}
