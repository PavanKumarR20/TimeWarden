import 'package:flutter_test/flutter_test.dart';
import 'package:timewarden/core/services/points_service.dart';
import 'package:timewarden/features/dashboard/domain/entities/user_stats.dart';
import 'package:timewarden/features/habits/domain/entities/habit.dart';

void main() {
  group('PointsService', () {
    late UserStats testStats;

    setUp(() {
      testStats = UserStats(
        userId: 'test-user',
        totalPointsToday: 100,
        lastPointsResetDate: DateTime.now(),
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
    });

    test('awardPoints adds points correctly', () {
      final newTotal = PointsService.awardPoints(
        userStats: testStats,
        pointsToAward: 10,
      );

      expect(newTotal, 110);
    });

    test('deductPoints subtracts points correctly', () {
      final newTotal = PointsService.deductPoints(
        userStats: testStats,
        pointsToDeduct: 20,
      );

      expect(newTotal, 80);
    });

    test('deductPoints cannot go below zero', () {
      final newTotal = PointsService.deductPoints(
        userStats: testStats,
        pointsToDeduct: 150,
      );

      expect(newTotal, 0);
    });

    test('manualAdjustPoints adds delta correctly', () {
      final newTotal = PointsService.manualAdjustPoints(
        userStats: testStats,
        delta: 25,
      );

      expect(newTotal, 125);
    });

    test('manualAdjustPoints subtracts delta correctly', () {
      final newTotal = PointsService.manualAdjustPoints(
        userStats: testStats,
        delta: -30,
      );

      expect(newTotal, 70);
    });

    test('manualAdjustPoints enforces minimum of zero', () {
      final newTotal = PointsService.manualAdjustPoints(
        userStats: testStats,
        delta: -200,
      );

      expect(newTotal, 0);
    });

    test('checkAndResetDaily resets when day changes', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final oldStats = testStats.copyWith(
        lastPointsResetDate: yesterday,
        totalPointsToday: 100,
      );

      final resetStats = PointsService.checkAndResetDaily(oldStats);

      expect(resetStats.totalPointsToday, 0);
      expect(resetStats.lastPointsResetDate.day, DateTime.now().day);
    });

    test('checkAndResetDaily does not reset same day', () {
      final resetStats = PointsService.checkAndResetDaily(testStats);

      expect(resetStats.totalPointsToday, 100);
    });

    test('isUnlimitedMode returns true when all active habits completed', () {
      final habits = [
        Habit(
          id: '1',
          name: 'Test Habit 1',
          frequency:
              const HabitFrequency(type: HabitFrequencyType.daily, target: 1),
          createdAt: DateTime.now(),
          isActive: true,
          completedDates: [DateTime.now()],
        ),
        Habit(
          id: '2',
          name: 'Test Habit 2',
          frequency:
              const HabitFrequency(type: HabitFrequencyType.daily, target: 1),
          createdAt: DateTime.now(),
          isActive: true,
          completedDates: [DateTime.now()],
        ),
      ];

      final isUnlimited = PointsService.isUnlimitedMode(habits: habits);
      expect(isUnlimited, true);
    });

    test('isUnlimitedMode returns false when some habits not completed', () {
      final habits = [
        Habit(
          id: '1',
          name: 'Test Habit 1',
          frequency:
              const HabitFrequency(type: HabitFrequencyType.daily, target: 1),
          createdAt: DateTime.now(),
          isActive: true,
          completedDates: [DateTime.now()],
        ),
        Habit(
          id: '2',
          name: 'Test Habit 2',
          frequency:
              const HabitFrequency(type: HabitFrequencyType.daily, target: 1),
          createdAt: DateTime.now(),
          isActive: true,
          completedDates: [],
        ),
      ];

      final isUnlimited = PointsService.isUnlimitedMode(habits: habits);
      expect(isUnlimited, false);
    });

    test('isUnlimitedMode returns false when no active habits', () {
      final habits = <Habit>[];

      final isUnlimited = PointsService.isUnlimitedMode(habits: habits);
      expect(isUnlimited, false);
    });

    test('getPointsDisplayText returns infinity symbol when unlimited', () {
      final display = PointsService.getPointsDisplayText(
        points: 100,
        isUnlimited: true,
      );

      expect(display, '∞');
    });

    test('getPointsDisplayText returns points number when not unlimited', () {
      final display = PointsService.getPointsDisplayText(
        points: 42,
        isUnlimited: false,
      );

      expect(display, '42');
    });
  });
}
