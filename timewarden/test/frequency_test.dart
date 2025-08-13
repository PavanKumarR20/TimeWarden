import 'package:flutter_test/flutter_test.dart';
import 'package:timewarden/features/habits/domain/entities/habit.dart';
import 'package:timewarden/features/habits/domain/entities/habit_filter.dart';

void main() {
  group('HabitFrequency Tests', () {
    test('daily frequency should display correctly', () {
      const frequency = HabitFrequency(
        type: HabitFrequencyType.daily,
        target: 1,
      );

      expect(frequency.displayText, equals('Every day'));
    });

    test('every N days frequency should display correctly', () {
      const frequency = HabitFrequency(
        type: HabitFrequencyType.everyNDays,
        target: 3,
      );

      expect(frequency.displayText, equals('Every 3 days'));
    });

    test('times per week frequency should display correctly', () {
      const frequency = HabitFrequency(
        type: HabitFrequencyType.timesPerWeek,
        target: 3,
      );

      expect(frequency.displayText, equals('3 times per week'));
    });

    test('times per month frequency should display correctly', () {
      const frequency = HabitFrequency(
        type: HabitFrequencyType.timesPerMonth,
        target: 5,
      );

      expect(frequency.displayText, equals('5 times per month'));
    });

    test('times in period frequency should display correctly', () {
      const frequency = HabitFrequency(
        type: HabitFrequencyType.timesInPeriod,
        target: 10,
      );

      expect(frequency.displayText, equals('10 times in period'));
    });
  });

  group('HabitFilter Tests', () {
    final habits = [
      Habit(
        id: '1',
        name: 'Completed Habit',
        description: null,
        category: HabitCategory.health,
        frequency: const HabitFrequency(type: HabitFrequencyType.daily, target: 1),
        createdAt: DateTime.now(),
        isActive: true,
        currentStreak: 5,
        longestStreak: 10,
        completedDates: [DateTime.now()],
      ),
      Habit(
        id: '2',
        name: 'Pending Habit',
        description: null,
        category: HabitCategory.productivity,
        frequency: const HabitFrequency(type: HabitFrequencyType.daily, target: 1),
        createdAt: DateTime.now(),
        isActive: true,
        currentStreak: 0,
        longestStreak: 0,
        completedDates: const [],
      ),
    ];

    test('all filter should return all habits', () {
      final filtered = HabitFilterService.filterHabits(habits, HabitFilter.all);
      expect(filtered.length, equals(2));
    });

    test('pending filter should return only pending habits', () {
      final filtered = HabitFilterService.filterHabits(habits, HabitFilter.pending);
      expect(filtered.length, equals(1));
      expect(filtered.first.name, equals('Pending Habit'));
    });

    test('completed filter should return only completed habits', () {
      final filtered = HabitFilterService.filterHabits(habits, HabitFilter.completed);
      expect(filtered.length, equals(1));
      expect(filtered.first.name, equals('Completed Habit'));
    });
  });
}
