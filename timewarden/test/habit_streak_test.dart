import 'package:flutter_test/flutter_test.dart';
import 'package:timewarden/features/habits/domain/entities/habit.dart';
import 'package:timewarden/core/services/habit_streak_service.dart';

void main() {
  group('HabitStreakService Tests', () {
    test('calculateCurrentStreak for daily habit with consecutive completions',
        () {
      final habit = Habit(
        id: '1',
        name: 'Daily Exercise',
        category: HabitCategory.health,
        frequency:
            const HabitFrequency(type: HabitFrequencyType.daily, target: 1),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        isActive: true,
        description: 'Test habit',
        icon: 'exercise',
        color: '#FF5722',
        completedDates: [
          DateTime.now().subtract(const Duration(days: 2)),
          DateTime.now().subtract(const Duration(days: 1)),
          DateTime.now(),
        ],
      );

      final streak = HabitStreakService.calculateCurrentStreak(habit);
      expect(streak, equals(3));
    });

    test('calculateCurrentStreak for weekly habit (3 times per week)', () {
      // Create dates for testing weekly streaks - use the same logic as debug test
      final now = DateTime.now();
      final currentWeekStart =
          now.subtract(Duration(days: now.weekday - 1)); // This Monday
      final lastWeekStart =
          currentWeekStart.subtract(const Duration(days: 7)); // Last Monday

      final habit = Habit(
        id: '2',
        name: 'Gym Workout',
        category: HabitCategory.health,
        frequency: const HabitFrequency(
            type: HabitFrequencyType.timesPerWeek, target: 3),
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        isActive: true,
        description: 'Test habit',
        icon: 'gym',
        color: '#2196F3',
        completedDates: [
          // This week - 3 completions (Mon, Wed, Fri)
          currentWeekStart, // Monday
          currentWeekStart.add(const Duration(days: 2)), // Wednesday
          currentWeekStart.add(const Duration(days: 4)), // Friday

          // Last week - 3 completions (Mon, Wed, Fri)
          lastWeekStart, // Monday
          lastWeekStart.add(const Duration(days: 2)), // Wednesday
          lastWeekStart.add(const Duration(days: 4)), // Friday
        ],
      );

      final streak = HabitStreakService.calculateCurrentStreak(habit);
      expect(streak,
          greaterThanOrEqualTo(1)); // Should have at least 1 week streak
    });

    test('getStreakStatusMessage returns correct messages', () {
      final dailyHabit = Habit(
        id: '1',
        name: 'Daily Reading',
        category: HabitCategory.learning,
        frequency:
            const HabitFrequency(type: HabitFrequencyType.daily, target: 1),
        createdAt: DateTime.now(),
        completedDates: [],
      );

      final weeklyHabit = Habit(
        id: '2',
        name: 'Weekly Gym',
        category: HabitCategory.fitness,
        frequency: const HabitFrequency(
            type: HabitFrequencyType.timesPerWeek, target: 3),
        createdAt: DateTime.now(),
        completedDates: [
          DateTime.now().subtract(const Duration(days: 1)),
          DateTime.now().subtract(const Duration(days: 3)),
          DateTime.now().subtract(const Duration(days: 5)),
        ],
      );

      expect(HabitStreakService.getStreakStatusMessage(dailyHabit),
          contains('Start your streak'));
      expect(HabitStreakService.getStreakStatusMessage(weeklyHabit),
          contains('streak'));
    });
  });
}
