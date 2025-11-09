import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/entities/pomodoro_statistics.dart';
import '../../domain/entities/pomodoro_settings.dart';
import '../../../../core/widgets/animations.dart';
import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_event.dart';
import '../bloc/pomodoro_state.dart';

enum StatisticsFilter {
  today,
  thisWeek,
  thisMonth,
  allTime,
  custom,
}

class PomodoroStatisticsPage extends StatefulWidget {
  const PomodoroStatisticsPage({super.key});

  @override
  State<PomodoroStatisticsPage> createState() => _PomodoroStatisticsPageState();
}

class _PomodoroStatisticsPageState extends State<PomodoroStatisticsPage> {
  StatisticsFilter _selectedFilter = StatisticsFilter.thisWeek;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    context.read<PomodoroBloc>().add(const PomodoroHistoryLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: BlocBuilder<PomodoroBloc, PomodoroState>(
        builder: (context, state) {
          // Handle error state
          if (state is PomodoroError) {
            return _buildErrorView(context, state.message);
          }

          // Handle history loaded state
          if (state is PomodoroHistoryLoaded) {
            return _buildStatisticsView(_applyFilter(state));
          }

          // Try to extract statistics from other states
          final statsData = _extractStatsFromState(state);
          if (statsData != null) {
            return _buildStatisticsView(_applyFilter(statsData));
          }

          // Show loading state
          return _buildLoadingView(context);
        },
      ),
    );
  }

  PomodoroHistoryLoaded _applyFilter(PomodoroHistoryLoaded state) {
    DateTime now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedFilter) {
      case StatisticsFilter.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case StatisticsFilter.thisWeek:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case StatisticsFilter.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case StatisticsFilter.allTime:
        startDate = null;
        endDate = null;
        break;
      case StatisticsFilter.custom:
        startDate = _customStartDate;
        endDate = _customEndDate;
        break;
    }

    // Filter sessions
    List<PomodoroSession> filteredSessions = state.sessions;
    if (startDate != null || endDate != null) {
      filteredSessions = state.sessions.where((session) {
        if (startDate != null && session.startTime.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && session.startTime.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();
    }

    // Recalculate statistics based on filtered sessions
    PomodoroStatistics filteredTodayStats = _calculateStatistics(
      filteredSessions.where((s) {
        DateTime today = DateTime.now();
        DateTime sessionDate = s.startTime;
        return sessionDate.year == today.year &&
            sessionDate.month == today.month &&
            sessionDate.day == today.day;
      }).toList(),
    );

    // Calculate weekly stats (last 7 days from filter end date or now)
    DateTime weekEnd = endDate ?? now;
    List<PomodoroStatistics> filteredWeeklyStats = [];
    for (int i = 6; i >= 0; i--) {
      DateTime day = weekEnd.subtract(Duration(days: i));
      DateTime dayStart = DateTime(day.year, day.month, day.day);
      DateTime dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);

      List<PomodoroSession> daySessions = filteredSessions.where((s) {
        return s.startTime.isAfter(dayStart) && s.startTime.isBefore(dayEnd);
      }).toList();

      filteredWeeklyStats.add(_calculateStatistics(daySessions));
    }

    return PomodoroHistoryLoaded(
      sessions: filteredSessions,
      todayStats: filteredTodayStats,
      weeklyStats: filteredWeeklyStats,
      settings: state.settings,
    );
  }

  PomodoroStatistics _calculateStatistics(List<PomodoroSession> sessions) {
    int completedWorkSessions = 0;
    int completedBreakSessions = 0;
    int totalWorkMinutes = 0;
    int totalBreakMinutes = 0;
    int cancelledSessions = 0;
    double totalCompletion = 0.0;

    for (var session in sessions) {
      if (session.status == SessionStatus.completed) {
        if (session.type == PomodoroType.work) {
          completedWorkSessions++;
          totalWorkMinutes += session.elapsedTime.inMinutes;
        } else {
          completedBreakSessions++;
          totalBreakMinutes += session.elapsedTime.inMinutes;
        }
        totalCompletion += session.progressPercentage;
      } else if (session.status == SessionStatus.cancelled) {
        cancelledSessions++;
      }
    }

    double averageCompletion =
        sessions.isNotEmpty ? totalCompletion / sessions.length : 0.0;

    return PomodoroStatistics(
      date: DateTime.now(),
      completedWorkSessions: completedWorkSessions,
      completedBreakSessions: completedBreakSessions,
      totalWorkMinutes: totalWorkMinutes,
      totalBreakMinutes: totalBreakMinutes,
      cancelledSessions: cancelledSessions,
      averageSessionCompletion: averageCompletion,
      sessions: sessions,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Statistics'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<StatisticsFilter>(
                  title: const Text('Today'),
                  value: StatisticsFilter.today,
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setDialogState(() => _selectedFilter = value!);
                  },
                ),
                RadioListTile<StatisticsFilter>(
                  title: const Text('This Week'),
                  value: StatisticsFilter.thisWeek,
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setDialogState(() => _selectedFilter = value!);
                  },
                ),
                RadioListTile<StatisticsFilter>(
                  title: const Text('This Month'),
                  value: StatisticsFilter.thisMonth,
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setDialogState(() => _selectedFilter = value!);
                  },
                ),
                RadioListTile<StatisticsFilter>(
                  title: const Text('All Time'),
                  value: StatisticsFilter.allTime,
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setDialogState(() => _selectedFilter = value!);
                  },
                ),
                RadioListTile<StatisticsFilter>(
                  title: const Text('Custom Range'),
                  value: StatisticsFilter.custom,
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setDialogState(() => _selectedFilter = value!);
                  },
                ),
                if (_selectedFilter == StatisticsFilter.custom) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _customStartDate == null
                          ? 'Select Start Date'
                          : 'Start: ${_formatDate(_customStartDate!)}',
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _customStartDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() => _customStartDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _customEndDate == null
                          ? 'Select End Date'
                          : 'End: ${_formatDate(_customEndDate!)}',
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _customEndDate ?? DateTime.now(),
                        firstDate: _customStartDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() => _customEndDate = date);
                      }
                    },
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {}); // Refresh the main view with new filter
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildFilterChip() {
    String filterText;
    switch (_selectedFilter) {
      case StatisticsFilter.today:
        filterText = 'Today';
        break;
      case StatisticsFilter.thisWeek:
        filterText = 'This Week';
        break;
      case StatisticsFilter.thisMonth:
        filterText = 'This Month';
        break;
      case StatisticsFilter.allTime:
        filterText = 'All Time';
        break;
      case StatisticsFilter.custom:
        if (_customStartDate != null && _customEndDate != null) {
          filterText =
              '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)}';
        } else {
          filterText = 'Custom Range';
        }
        break;
    }

    return Row(
      children: [
        Icon(
          Icons.filter_list,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Chip(
          label: Text(filterText),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide.none,
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load statistics',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadStatistics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading statistics...'),
        ],
      ),
    );
  }

  PomodoroHistoryLoaded? _extractStatsFromState(PomodoroState state) {
    PomodoroStatistics? todayStats;
    List<PomodoroStatistics>? weeklyStats;
    List<PomodoroSession>? sessions;
    PomodoroSettings settings = const PomodoroSettings();

    if (state is PomodoroRunning && state.todayStats != null) {
      todayStats = state.todayStats!;
      weeklyStats = state.weeklyStats!;
      sessions = state.sessions!;
      settings = state.settings;
    } else if (state is PomodoroPaused && state.todayStats != null) {
      todayStats = state.todayStats!;
      weeklyStats = state.weeklyStats!;
      sessions = state.sessions!;
      settings = state.settings;
    }

    if (todayStats != null && weeklyStats != null && sessions != null) {
      return PomodoroHistoryLoaded(
        sessions: sessions,
        todayStats: todayStats,
        weeklyStats: weeklyStats,
        settings: settings,
      );
    }

    return null;
  }

  Widget _buildEmptyChartMessage(BuildContext context, String message) {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsView(PomodoroHistoryLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chip
          _buildFilterChip(),

          const SizedBox(height: 16),

          // Today's Summary
          SlideInAnimation(
            child: _buildTodaysSummary(context, state.todayStats),
          ),

          const SizedBox(height: 24),

          // Weekly Chart
          SlideInAnimation(
            delay: const Duration(milliseconds: 100),
            child: _buildWeeklyChart(context, state.weeklyStats),
          ),

          const SizedBox(height: 24),

          // Detailed Statistics
          SlideInAnimation(
            delay: const Duration(milliseconds: 200),
            child: _buildDetailedStats(context, state.todayStats),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSummary(BuildContext context, PomodoroStatistics stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Focus Sessions',
                    stats.completedWorkSessions.toString(),
                    Icons.work_outline,
                    Colors.red.shade400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Focus Time',
                    '${stats.totalWorkMinutes}m',
                    Icons.timer_outlined,
                    Colors.blue.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(
      BuildContext context, List<PomodoroStatistics> weeklyStats) {
    // Safety check for empty or null data
    if (weeklyStats.isEmpty) {
      return _buildEmptyChartMessage(context, 'No weekly data available');
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Focus Time',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: () {
                    final maxMinutes = weeklyStats.isEmpty
                        ? 0.0
                        : weeklyStats
                            .map((s) => s.totalWorkMinutes.toDouble())
                            .reduce((a, b) => a > b ? a : b);
                    return maxMinutes + 10.0;
                  }(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}m',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ];
                          if (value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: weeklyStats.asMap().entries.map((entry) {
                    // Safety check for valid data
                    final workMinutes = entry.value.totalWorkMinutes;
                    final safeValue =
                        workMinutes.isNaN || workMinutes.isInfinite
                            ? 0.0
                            : workMinutes
                                .clamp(0, 1440)
                                .toDouble(); // Max 24 hours per day

                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: safeValue,
                          color: Theme.of(context).colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context, PomodoroStatistics stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
                context, 'Total Sessions', '${stats.totalSessions}'),
            _buildDetailRow(
                context, 'Work Sessions', '${stats.completedWorkSessions}'),
            _buildDetailRow(
                context, 'Break Sessions', '${stats.completedBreakSessions}'),
            _buildDetailRow(context, 'Total Focus Time',
                _formatDuration(stats.totalFocusTime)),
            _buildDetailRow(context, 'Total Break Time',
                _formatDuration(stats.totalBreakTime)),
            _buildDetailRow(context, 'Average Session Completion',
                '${_safePercentage(stats.averageSessionCompletion * 100)}%'),
            _buildDetailRow(
                context, 'Cancelled Sessions', '${stats.cancelledSessions}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _safePercentage(double value) {
    if (value.isNaN || value.isInfinite) return '0.0';
    return value.clamp(0.0, 100.0).toStringAsFixed(1);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
