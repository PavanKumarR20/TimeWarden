import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_event.dart';
import '../bloc/pomodoro_state.dart';

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

class PomodoroHeatmapPage extends StatefulWidget {
  const PomodoroHeatmapPage({super.key});

  @override
  State<PomodoroHeatmapPage> createState() => _PomodoroHeatmapPageState();
}

class _PomodoroHeatmapPageState extends State<PomodoroHeatmapPage> {
  CalendarFilter _selectedFilter = CalendarFilter.lastMonth;

  @override
  void initState() {
    super.initState();
    // Load history when page opens
    context.read<PomodoroBloc>().add(const PomodoroHistoryLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Activity'),
        elevation: 0,
      ),
      body: BlocBuilder<PomodoroBloc, PomodoroState>(
        builder: (context, state) {
          List<PomodoroSession> sessions = [];

          // Extract sessions from various states
          if (state is PomodoroHistoryLoaded) {
            sessions = state.sessions;
          } else if (state is PomodoroRunning) {
            sessions = state.sessions ?? [];
          } else if (state is PomodoroPaused) {
            sessions = state.sessions ?? [];
          }

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Pomodoro sessions yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your first session to see your activity',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return _buildHeatmapView(context, sessions);
        },
      ),
    );
  }

  Widget _buildHeatmapView(
      BuildContext context, List<PomodoroSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = _selectedFilter.getStartDate(today);

    // Filter completed work sessions based on selected period
    final filteredSessions = sessions.where((session) {
      if (session.type != PomodoroType.work || !session.isCompleted) {
        return false;
      }
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      return (sessionDate.isAtSameMomentAs(startDate) ||
              sessionDate.isAfter(startDate)) &&
          (sessionDate.isBefore(today) || sessionDate.isAtSameMomentAs(today));
    }).toList();

    // Group sessions by date and count
    final Map<DateTime, int> sessionCounts = {};
    for (final session in filteredSessions) {
      final dateOnly = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      sessionCounts[dateOnly] = (sessionCounts[dateOnly] ?? 0) + 1;
    }

    // Calculate total stats
    final totalSessions = filteredSessions.length;
    final totalMinutes = filteredSessions.fold<int>(
        0, (sum, session) => sum + session.durationMinutes);
    final uniqueDays = sessionCounts.keys.length;

    // Find max sessions in a day for color intensity
    final maxSessionsPerDay = sessionCounts.values.isEmpty
        ? 1
        : sessionCounts.values.reduce((a, b) => a > b ? a : b);

    // Convert to heatmap format (normalize to 0-10 scale)
    final Map<DateTime, int> datasets = {};
    sessionCounts.forEach((date, count) {
      // Scale to 1-10 based on count relative to max
      datasets[date] = ((count / maxSessionsPerDay) * 10).ceil().clamp(1, 10);
    });

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
                  1: Colors.green,
                },
                onClick: (value) {
                  final dateOnly = DateTime(value.year, value.month, value.day);
                  final count = sessionCounts[dateOnly] ?? 0;
                  final dateStr = '${value.day}/${value.month}/${value.year}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(count > 0
                          ? '🍅 $count session${count > 1 ? 's' : ''} on $dateStr'
                          : '⭕ No sessions on $dateStr'),
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
                  'Total Sessions',
                  '$totalSessions',
                  Icons.timer,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Focus Time',
                  '${totalMinutes}m',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Active Days',
                  '$uniqueDays',
                  Icons.calendar_today,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legend
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Less',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 8),
                ...[0.2, 0.4, 0.6, 0.8, 1.0].map((opacity) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(opacity),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  'More',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
