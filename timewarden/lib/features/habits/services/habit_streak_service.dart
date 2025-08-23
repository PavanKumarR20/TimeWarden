import '../domain/entities/habit.dart';
import '../../../core/services/log_service.dart';

/// Service for calculating smart habit streaks based on habit frequency
class HabitStreakService {
  /// Calculate current streak for a habit based on its frequency
  static int calculateCurrentStreak(Habit habit) {
    if (habit.completedDates.isEmpty) {
      LogService.debug('No completed dates for habit: ${habit.name}');
      return 0;
    }

    final sortedDates = List<DateTime>.from(habit.completedDates)
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    final today = DateTime.now();
    
    switch (habit.frequency.type) {
      case HabitFrequencyType.daily:
        return _calculateDailyStreak(sortedDates, today);
      
      case HabitFrequencyType.everyNDays:
        return _calculateEveryNDaysStreak(sortedDates, today, habit.frequency.target);
      
      case HabitFrequencyType.timesPerWeek:
        return _calculateWeeklyStreak(sortedDates, today, habit.frequency.target);
      
      case HabitFrequencyType.timesPerMonth:
        return _calculateMonthlyStreak(sortedDates, today, habit.frequency.target);
      
      case HabitFrequencyType.timesInPeriod:
        return _calculatePeriodStreak(
          sortedDates, 
          today, 
          habit.frequency.target, 
          habit.frequency.periodDays ?? 7
        );
    }
  }

  /// Calculate streak for daily habits
  static int _calculateDailyStreak(List<DateTime> sortedDates, DateTime today) {
    int streak = 0;
    DateTime checkDate = today;
    
    for (int i = 0; i < sortedDates.length; i++) {
      final completedDate = sortedDates[i];
      
      // Check if habit was completed on the expected date
      if (_isSameDay(completedDate, checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (_isSameDay(completedDate, checkDate.subtract(const Duration(days: 1)))) {
        // Allow for today not being completed yet if it's still today
        if (_isSameDay(checkDate, today)) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          if (_isSameDay(completedDate, checkDate)) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          }
        } else {
          break;
        }
      } else {
        break;
      }
    }
    
    LogService.debug('Daily streak calculated: $streak');
    return streak;
  }

  /// Calculate streak for every N days habits
  static int _calculateEveryNDaysStreak(List<DateTime> sortedDates, DateTime today, int nDays) {
    if (sortedDates.isEmpty) return 0;
    
    int streak = 0;
    DateTime expectedDate = sortedDates.first;
    
    for (final completedDate in sortedDates) {
      if (_isWithinExpectedRange(completedDate, expectedDate, 1)) {
        streak++;
        expectedDate = expectedDate.subtract(Duration(days: nDays));
      } else {
        break;
      }
    }
    
    LogService.debug('Every $nDays days streak calculated: $streak');
    return streak;
  }

  /// Calculate streak for X times per week habits
  static int _calculateWeeklyStreak(List<DateTime> sortedDates, DateTime today, int targetPerWeek) {
    if (sortedDates.isEmpty) return 0;
    
    final weeks = _groupDatesByWeek(sortedDates);
    int streak = 0;
    
    // Start from the most recent week
    final sortedWeeks = weeks.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final weekStart in sortedWeeks) {
      final weekDates = weeks[weekStart]!;
      
      if (weekDates.length >= targetPerWeek) {
        streak++;
      } else {
        // If it's the current week, don't break the streak yet
        if (_isCurrentWeek(weekStart, today)) {
          // Continue without breaking, but don't increment
          continue;
        } else {
          break;
        }
      }
    }
    
    LogService.debug('Weekly streak ($targetPerWeek times/week) calculated: $streak');
    return streak;
  }

  /// Calculate streak for X times per month habits
  static int _calculateMonthlyStreak(List<DateTime> sortedDates, DateTime today, int targetPerMonth) {
    if (sortedDates.isEmpty) return 0;
    
    final months = _groupDatesByMonth(sortedDates);
    int streak = 0;
    
    // Start from the most recent month
    final sortedMonths = months.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final monthStart in sortedMonths) {
      final monthDates = months[monthStart]!;
      
      if (monthDates.length >= targetPerMonth) {
        streak++;
      } else {
        // If it's the current month, don't break the streak yet
        if (_isCurrentMonth(monthStart, today)) {
          continue;
        } else {
          break;
        }
      }
    }
    
    LogService.debug('Monthly streak ($targetPerMonth times/month) calculated: $streak');
    return streak;
  }

  /// Calculate streak for X times in Y days habits
  static int _calculatePeriodStreak(List<DateTime> sortedDates, DateTime today, int target, int periodDays) {
    if (sortedDates.isEmpty) return 0;
    
    int streak = 0;
    DateTime periodEnd = today;
    
    while (true) {
      final periodStart = periodEnd.subtract(Duration(days: periodDays - 1));
      final datesInPeriod = sortedDates.where((date) =>
          date.isAfter(periodStart.subtract(const Duration(days: 1))) &&
          date.isBefore(periodEnd.add(const Duration(days: 1)))
      ).length;
      
      if (datesInPeriod >= target) {
        streak++;
        periodEnd = periodStart.subtract(const Duration(days: 1));
      } else {
        break;
      }
      
      // Safety check to avoid infinite loop
      if (periodEnd.isBefore(sortedDates.last.subtract(Duration(days: periodDays)))) {
        break;
      }
    }
    
    LogService.debug('Period streak ($target times in $periodDays days) calculated: $streak');
    return streak;
  }

  /// Group dates by week (Monday as start of week)
  static Map<DateTime, List<DateTime>> _groupDatesByWeek(List<DateTime> dates) {
    final Map<DateTime, List<DateTime>> weeks = {};
    
    for (final date in dates) {
      final weekStart = _getWeekStart(date);
      weeks[weekStart] = (weeks[weekStart] ?? [])..add(date);
    }
    
    return weeks;
  }

  /// Group dates by month
  static Map<DateTime, List<DateTime>> _groupDatesByMonth(List<DateTime> dates) {
    final Map<DateTime, List<DateTime>> months = {};
    
    for (final date in dates) {
      final monthStart = DateTime(date.year, date.month, 1);
      months[monthStart] = (months[monthStart] ?? [])..add(date);
    }
    
    return months;
  }

  /// Get the start of the week (Monday) for a given date
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // Monday = 1, Sunday = 7
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Check if a date is within expected range
  static bool _isWithinExpectedRange(DateTime actual, DateTime expected, int toleranceDays) {
    final diff = actual.difference(expected).inDays.abs();
    return diff <= toleranceDays;
  }

  /// Check if date is in current week
  static bool _isCurrentWeek(DateTime weekStart, DateTime today) {
    final currentWeekStart = _getWeekStart(today);
    return _isSameDay(weekStart, currentWeekStart);
  }

  /// Check if date is in current month
  static bool _isCurrentMonth(DateTime monthStart, DateTime today) {
    return monthStart.year == today.year && monthStart.month == today.month;
  }

  /// Get streak status message
  static String getStreakStatusMessage(Habit habit) {
    final streak = calculateCurrentStreak(habit);
    
    if (streak == 0) {
      return "Start your streak today!";
    } else if (streak == 1) {
      return "Great start! Keep it going.";
    } else if (streak < 7) {
      return "$streak ${_getPeriodName(habit.frequency.type)} streak! 🔥";
    } else if (streak < 30) {
      return "Amazing $streak ${_getPeriodName(habit.frequency.type)} streak! 🚀";
    } else {
      return "Incredible $streak ${_getPeriodName(habit.frequency.type)} streak! 🏆";
    }
  }

  /// Get period name for streak display
  static String _getPeriodName(HabitFrequencyType type) {
    switch (type) {
      case HabitFrequencyType.daily:
        return "day";
      case HabitFrequencyType.everyNDays:
        return "cycle";
      case HabitFrequencyType.timesPerWeek:
        return "week";
      case HabitFrequencyType.timesPerMonth:
        return "month";
      case HabitFrequencyType.timesInPeriod:
        return "period";
    }
  }
}
