import '../../features/habits/domain/entities/habit.dart' as habit_entity;
import '../../features/dashboard/domain/entities/user_stats.dart';
import 'log_service.dart';

/// Service for managing the points system
class PointsService {
  /// Award points when a habit is completed
  /// Returns the new total points for today
  static double awardPoints({
    required UserStats userStats,
    required double pointsToAward,
  }) {
    LogService.info(
        'Awarding $pointsToAward points (current: ${userStats.totalPointsToday})',
        tag: 'PointsService');

    final newTotal = userStats.totalPointsToday + pointsToAward;

    LogService.info('New points total: $newTotal', tag: 'PointsService');
    return newTotal;
  }

  /// Deduct points when a habit completion is removed
  /// Returns the new total points for today (minimum 0)
  static double deductPoints({
    required UserStats userStats,
    required double pointsToDeduct,
  }) {
    LogService.info(
        'Deducting $pointsToDeduct points (current: ${userStats.totalPointsToday})',
        tag: 'PointsService');

    final newTotal = (userStats.totalPointsToday - pointsToDeduct)
        .clamp(0.0, double.infinity);

    LogService.info('New points total: $newTotal', tag: 'PointsService');
    return newTotal;
  }

  /// Check if daily reset is needed and return the reset stats
  /// Compares lastPointsResetDate with current date
  static UserStats checkAndResetDaily(UserStats userStats) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(
      userStats.lastPointsResetDate.year,
      userStats.lastPointsResetDate.month,
      userStats.lastPointsResetDate.day,
    );

    // Check if we need to reset (different day)
    if (today.isAfter(lastReset)) {
      LogService.info(
        'Resetting daily points from ${userStats.totalPointsToday} to 0 (lastReset: ${lastReset.toIso8601String()}, today: ${today.toIso8601String()})',
        tag: 'PointsService',
      );

      return userStats.copyWith(
        totalPointsToday: 0.0,
        lastPointsResetDate: today,
      );
    }

    return userStats;
  }

  /// Check if unlimited mode should be active
  /// Returns true if all active habits are completed for today
  static bool isUnlimitedMode({
    required List<habit_entity.Habit> habits,
  }) {
    final activeHabits = habits.where((h) => h.isActive).toList();

    if (activeHabits.isEmpty) {
      LogService.info('No active habits, unlimited mode: false',
          tag: 'PointsService');
      return false;
    }

    final allCompleted = activeHabits.every((habit) {
      // For daily habits, check if completed today
      if (habit.frequency.type == habit_entity.HabitFrequencyType.daily) {
        return habit.isCompletedToday;
      }
      // For other frequency types, check if completed for current period
      return habit.isCompletedForCurrentPeriod;
    });

    final completedCount = activeHabits
        .where((h) => h.frequency.type == habit_entity.HabitFrequencyType.daily
            ? h.isCompletedToday
            : h.isCompletedForCurrentPeriod)
        .length;

    LogService.info(
      'Unlimited mode check: $allCompleted (activeHabits: ${activeHabits.length}, completedHabits: $completedCount)',
      tag: 'PointsService',
    );

    return allCompleted;
  }

  /// Manually adjust points (can increase or decrease)
  /// Delta can be positive or negative, result is clamped to minimum 0
  static double manualAdjustPoints({
    required UserStats userStats,
    required double delta,
  }) {
    LogService.info(
      'Manually adjusting points by $delta (current: ${userStats.totalPointsToday})',
      tag: 'PointsService',
    );

    final newTotal =
        (userStats.totalPointsToday + delta).clamp(0.0, double.infinity);

    LogService.info('New points total after manual adjustment: $newTotal',
        tag: 'PointsService');
    return newTotal;
  }

  /// Get display text for points (returns "∞" if unlimited mode)
  static String getPointsDisplayText({
    required double points,
    required bool isUnlimited,
  }) {
    if (isUnlimited) {
      return '∞';
    }
    // Format to remove unnecessary decimal zeros
    return points == points.toInt()
        ? points.toInt().toString()
        : points.toStringAsFixed(1);
  }
}
