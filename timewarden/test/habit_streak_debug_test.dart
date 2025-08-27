import 'package:flutter_test/flutter_test.dart';
import 'package:timewarden/features/habits/domain/entities/habit.dart';
import 'package:timewarden/core/services/habit_streak_service.dart';

void main() {
  group('HabitStreakService Debug Tests', () {
    test('debug weekly streak calculation with real dates', () {
      // Use actual dates for debugging
      final now = DateTime.now();
      print('Current date: $now');
      print('Current weekday: ${now.weekday}'); // Monday = 1

      // Calculate this Monday
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      print('Current week start (Monday): $currentWeekStart');

      // Calculate last Monday
      final lastWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      print('Last week start (Monday): $lastWeekStart');

      final habit = Habit(
        id: '1',
        name: 'Weekly Test',
        category: HabitCategory.health,
        frequency: const HabitFrequency(
            type: HabitFrequencyType.timesPerWeek, target: 3),
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        completedDates: [
          // This week - 3 completions
          currentWeekStart, // Monday
          currentWeekStart.add(const Duration(days: 2)), // Wednesday
          currentWeekStart.add(const Duration(days: 4)), // Friday

          // Last week - 3 completions
          lastWeekStart, // Monday
          lastWeekStart.add(const Duration(days: 2)), // Wednesday
          lastWeekStart.add(const Duration(days: 4)), // Friday
        ],
      );

      print('Habit completed dates:');
      for (final date in habit.completedDates) {
        print('  $date (weekday: ${date.weekday})');
      }

      final streak = HabitStreakService.calculateCurrentStreak(habit);
      print('Calculated streak: $streak');

      // This should pass since we have 3 completions in both weeks
      expect(streak, greaterThanOrEqualTo(1),
          reason: 'Should have streak of at least 1 week');
    });

    test('debug daily streak calculation', () {
      final now = DateTime.now();
      final habit = Habit(
        id: '2',
        name: 'Daily Test',
        category: HabitCategory.health,
        frequency:
            const HabitFrequency(type: HabitFrequencyType.daily, target: 1),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        completedDates: [
          now, // Today
          now.subtract(const Duration(days: 1)), // Yesterday
          now.subtract(const Duration(days: 2)), // Day before yesterday
        ],
      );

      final streak = HabitStreakService.calculateCurrentStreak(habit);
      print('Daily streak: $streak');
      expect(streak, equals(3));
    });
  });
}
