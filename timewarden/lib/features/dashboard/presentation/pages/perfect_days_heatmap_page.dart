import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/repositories/user_stats_repository_impl.dart';
import '../../../habits/data/repositories/habit_repository_impl.dart';

enum CalendarFilter {
  lastWeek,
  lastMonth,
  last3Months,
  last6Months,
  thisYear,
  allTime,
}

extension CalendarFilterExtension on CalendarFilter {
  String get label {
    switch (this) {
      case CalendarFilter.lastWeek:
        return '7 Days';
      case CalendarFilter.lastMonth:
        return '30 Days';
      case CalendarFilter.last3Months:
        return '3 Months';
      case CalendarFilter.last6Months:
        return '6 Months';
      case CalendarFilter.thisYear:
        return 'This Year';
      case CalendarFilter.allTime:
        return 'All Time';
    }
  }

  DateTime getStartDate(DateTime now) {
    switch (this) {
      case CalendarFilter.lastWeek:
        return now.subtract(const Duration(days: 6));
      case CalendarFilter.lastMonth:
        return now.subtract(const Duration(days: 29));
      case CalendarFilter.last3Months:
        return now.subtract(const Duration(days: 89));
      case CalendarFilter.last6Months:
        return now.subtract(const Duration(days: 179));
      case CalendarFilter.thisYear:
        return DateTime(now.year, 1, 1);
      case CalendarFilter.allTime:
        return DateTime(2020, 1, 1); // Arbitrary start date
    }
  }
}

class PerfectDaysHeatmapPage extends StatefulWidget {
  const PerfectDaysHeatmapPage({super.key});

  @override
  State<PerfectDaysHeatmapPage> createState() => _PerfectDaysHeatmapPageState();
}

class _PerfectDaysHeatmapPageState extends State<PerfectDaysHeatmapPage> {
  CalendarFilter _selectedFilter = CalendarFilter.lastMonth;
  List<DateTime> _perfectDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerfectDays();
  }

  Future<void> _loadPerfectDays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseService().currentUserId;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get perfect day dates from user stats
      final statsRepository = UserStatsRepositoryImpl(FirebaseService());
      final userStats = await statsRepository.getUserStats(userId);

      print('🔍 Perfect Days Heatmap Debug:');
      print('   User Stats: ${userStats != null ? "Found" : "NULL"}');
      print('   Perfect Days Count: ${userStats?.perfectDays ?? 0}');
      
      // Get all completed habits to reconstruct perfect days
      final habitsRepository = HabitRepositoryImpl(FirebaseService());
      List<DateTime> perfectDaysList = [];
      
      try {
        final habits = await habitsRepository.getHabits();
      
      if (habits.isNotEmpty) {
        // Find all dates where ALL active habits were completed
        // Get the earliest habit creation date
        DateTime earliestDate = habits
            .map((h) => h.createdAt)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        
        DateTime checkDate = DateTime.now();
        DateTime startDate = DateTime(earliestDate.year, earliestDate.month, earliestDate.day);
        
        // Check each day from earliest to today
        while (checkDate.isAfter(startDate) || checkDate.isAtSameMomentAs(startDate)) {
          final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
          
          // Get habits that existed on this day
          final habitsForDay = habits.where((habit) {
            final habitCreated = DateTime(
              habit.createdAt.year,
              habit.createdAt.month,
              habit.createdAt.day,
            );
            return habitCreated.isBefore(dayStart) || habitCreated.isAtSameMomentAs(dayStart);
          }).toList();
          
          if (habitsForDay.isNotEmpty) {
            // Check if ALL habits were completed on this day
            final allCompleted = habitsForDay.every((habit) {
              return habit.completedDates.any((date) {
                final completedDay = DateTime(date.year, date.month, date.day);
                return completedDay.isAtSameMomentAs(dayStart);
              });
            });
            
            if (allCompleted) {
              perfectDaysList.add(dayStart);
            }
          }
          
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }
      } catch (e) {
        print('⚠️ Error loading habits: $e');
      }

      print('✅ Reconstructed ${perfectDaysList.length} perfect days from habits');

      setState(() {
        _perfectDays = perfectDaysList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading perfect days: $e');
      setState(() {
        _perfectDays = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfect Days'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildHeatmapView(context),
    );
  }

  Widget _buildHeatmapView(BuildContext context) {
    print(
        'DEBUG: Building heatmap view with ${_perfectDays.length} perfect days');

    if (_perfectDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No perfect days yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete all your habits in a day to achieve perfection!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _loadPerfectDays();
              },
              child: const Text('Reload'),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = _selectedFilter.getStartDate(today);

    // Filter perfect days based on selected period
    final filteredDays = _perfectDays.where((date) {
      return (date.isAtSameMomentAs(startDate) || date.isAfter(startDate)) &&
          (date.isBefore(today) || date.isAtSameMomentAs(today));
    }).toList();

    // Convert to heatmap format
    final Map<DateTime, int> datasets = {};
    for (final date in filteredDays) {
      datasets[date] = 1; // All perfect days have same weight
    }

    // Calculate stats
    final totalPerfectDays = filteredDays.length;

    // Calculate current streak
    int currentStreak = 0;
    DateTime checkDate = today;
    while (_perfectDays.any((d) => d.isAtSameMomentAs(checkDate))) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Calculate best streak
    int bestStreak = 0;
    int tempStreak = 0;
    final sortedDays = List<DateTime>.from(_perfectDays)..sort();

    for (int i = 0; i < sortedDays.length; i++) {
      if (i == 0) {
        tempStreak = 1;
      } else {
        final daysDiff = sortedDays[i].difference(sortedDays[i - 1]).inDays;
        if (daysDiff == 1) {
          tempStreak++;
        } else {
          bestStreak = tempStreak > bestStreak ? tempStreak : bestStreak;
          tempStreak = 1;
        }
      }
    }
    bestStreak = tempStreak > bestStreak ? tempStreak : bestStreak;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter and title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButton<CalendarFilter>(
                  value: _selectedFilter,
                  underline: const SizedBox(),
                  isDense: true,
                  items: CalendarFilter.values.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(
                        filter.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFilter = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Heatmap calendar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: HeatMap(
                startDate: startDate,
                endDate: today,
                datasets: datasets,
                colorMode: ColorMode.opacity,
                defaultColor: Theme.of(context).colorScheme.surfaceContainer,
                textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                showColorTip: false,
                showText: false,
                scrollable: false,
                size: 24,
                margin: const EdgeInsets.all(2),
                borderRadius: 4,
                colorsets: {
                  1: Colors.amber, // Gold for perfect days
                },
                onClick: (value) {
                  final dateOnly = DateTime(value.year, value.month, value.day);
                  final isPerfect =
                      _perfectDays.any((d) => d.isAtSameMomentAs(dateOnly));
                  final dateStr = '${value.day}/${value.month}/${value.year}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isPerfect
                          ? '⭐ Perfect day on $dateStr'
                          : '⭕ Not a perfect day on $dateStr'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Stats cards
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Perfect Days',
                  '$totalPerfectDays',
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Current Streak',
                  '$currentStreak',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Best Streak',
                  '$bestStreak',
                  Icons.emoji_events,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A perfect day is when you complete all your active habits.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.amber.shade900,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
