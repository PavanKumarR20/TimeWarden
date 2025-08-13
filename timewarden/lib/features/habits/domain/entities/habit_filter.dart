import '../entities/habit.dart';

enum HabitFilter {
  all,
  pending, // Not completed today
  completed, // Completed today
}

extension HabitFilterExtension on HabitFilter {
  String get displayName {
    switch (this) {
      case HabitFilter.all:
        return 'All Habits';
      case HabitFilter.pending:
        return 'Pending';
      case HabitFilter.completed:
        return 'Completed';
    }
  }

  bool shouldShow(Habit habit, {DateTime? forDate}) {
    final date = forDate ?? DateTime.now();

    // Don't show inactive habits
    if (!habit.isActive) return false;

    // Don't show habits that aren't required on this date
    if (!habit.isRequiredOnDate(date)) return false;

    switch (this) {
      case HabitFilter.all:
        return true;
      case HabitFilter.pending:
        return !habit.isCompletedOnDate(date);
      case HabitFilter.completed:
        return habit.isCompletedOnDate(date);
    }
  }
}

class HabitFilterService {
  static List<Habit> filterHabits(
    List<Habit> habits,
    HabitFilter filter, {
    DateTime? forDate,
  }) {
    final date = forDate ?? DateTime.now();
    return habits
        .where((habit) => filter.shouldShow(habit, forDate: date))
        .toList();
  }

  static List<Habit> getHabitsForWeek(
    List<Habit> habits,
    DateTime startOfWeek,
  ) {
    // Get habits that should appear at least once during the week
    return habits.where((habit) {
      if (!habit.isActive) return false;

      // Check if habit should show on any day of the week
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        if (habit.shouldShowOnDate(date)) {
          return true;
        }
      }
      return false;
    }).toList();
  }
}
