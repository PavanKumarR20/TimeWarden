import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/entities/pomodoro_statistics.dart';
import '../../../../core/widgets/animations.dart';
import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_event.dart';
import '../bloc/pomodoro_state.dart';

class PomodoroStatisticsPage extends StatefulWidget {
  const PomodoroStatisticsPage({super.key});

  @override
  State<PomodoroStatisticsPage> createState() => _PomodoroStatisticsPageState();
}

class _PomodoroStatisticsPageState extends State<PomodoroStatisticsPage> {
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    context.read<PomodoroBloc>().add(const PomodoroHistoryLoadRequested());

    // Add a timeout fallback
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted &&
          context.read<PomodoroBloc>().state is! PomodoroHistoryLoaded) {
        // If still loading after 10 seconds, attempt retry
        print('Statistics loading timeout, attempting to recover...');
        context.read<PomodoroBloc>().add(const PomodoroHistoryLoadRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Statistics'),
      ),
      body: BlocBuilder<PomodoroBloc, PomodoroState>(
        builder: (context, state) {
          if (state is PomodoroError) {
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
                    state.message,
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

          if (state is PomodoroHistoryLoaded) {
            return _buildStatisticsView(context, state);
          }

          // Loading state
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
        },
      ),
    );
  }

  Widget _buildStatisticsView(
      BuildContext context, PomodoroHistoryLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          const SizedBox(height: 24),

          // Recent Sessions
          SlideInAnimation(
            delay: const Duration(milliseconds: 300),
            child: _buildRecentSessions(context, state.sessions),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Completion Rate',
                    '${stats.completionRate.toStringAsFixed(0)}%',
                    Icons.check_circle_outline,
                    Colors.green.shade400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Focus Efficiency',
                    '${stats.focusEfficiency.toStringAsFixed(0)}%',
                    Icons.trending_up,
                    Colors.orange.shade400,
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
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.totalWorkMinutes.toDouble(),
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
                '${(stats.averageSessionCompletion * 100).toStringAsFixed(1)}%'),
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

  Widget _buildRecentSessions(
      BuildContext context, List<PomodoroSession> sessions) {
    final recentSessions = sessions.take(10).toList();

    if (recentSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Recent Sessions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'No sessions yet. Start your first Pomodoro!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ...recentSessions
                .map((session) => _buildSessionItem(context, session)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, PomodoroSession session) {
    Color sessionColor = _getSessionColor(session.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sessionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: sessionColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: sessionColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayType,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: sessionColor,
                      ),
                ),
                if (session.taskDescription != null) ...[
                  Text(
                    session.taskDescription!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDuration(session.elapsedTime),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                _getStatusText(session.status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(session.status),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSessionColor(PomodoroType type) {
    switch (type) {
      case PomodoroType.work:
        return Colors.red.shade400;
      case PomodoroType.shortBreak:
        return Colors.green.shade400;
      case PomodoroType.longBreak:
        return Colors.blue.shade400;
    }
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.completed:
        return Colors.green.shade600;
      case SessionStatus.cancelled:
        return Colors.red.shade600;
      case SessionStatus.active:
        return Colors.blue.shade600;
      case SessionStatus.paused:
        return Colors.orange.shade600;
      case SessionStatus.pending:
        return Colors.grey.shade600;
    }
  }

  String _getStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
      case SessionStatus.active:
        return 'Active';
      case SessionStatus.paused:
        return 'Paused';
      case SessionStatus.pending:
        return 'Pending';
    }
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
