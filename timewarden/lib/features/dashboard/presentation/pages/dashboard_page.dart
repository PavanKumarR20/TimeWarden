import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../habits/presentation/pages/habits_page.dart';
import '../../../habits/presentation/bloc/habits_bloc.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../pomodoro/presentation/pages/pomodoro_page.dart';
import '../../../pomodoro/presentation/bloc/pomodoro_bloc.dart';
import '../../../pomodoro/presentation/bloc/pomodoro_state.dart';
import '../../../pomodoro/presentation/bloc/pomodoro_event.dart';
import '../../../journal/presentation/bloc/journal_bloc.dart';
import '../../../journal/presentation/bloc/journal_event.dart';
import '../../../journal/presentation/bloc/goal_bloc.dart';
import '../../../journal/presentation/bloc/goal_event.dart';
import '../../../journal/presentation/bloc/goal_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../journal/presentation/pages/secure_journal_page.dart';
import 'perfect_days_heatmap_page.dart';
import '../../../../core/services/quotes_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/points_detail_dialog.dart';
import '../../domain/entities/user_stats.dart';
import '../../data/repositories/user_stats_repository_impl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLastSelectedTab();
  }

  Future<void> _loadLastSelectedTab() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSelectedTab = prefs.getInt('last_selected_tab') ?? 0;
    if (mounted) {
      setState(() {
        _selectedIndex = lastSelectedTab;
      });
    }
  }

  Future<void> _saveSelectedTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_selected_tab', index);
  }

  void _onNavigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _saveSelectedTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Check if there's an active Pomodoro session
        final pomodoroState = context.read<PomodoroBloc>().state;
        final bool hasActiveSession =
            pomodoroState is PomodoroRunning || pomodoroState is PomodoroPaused;

        if (hasActiveSession) {
          // Show warning dialog for active session
          final shouldExit =
              await _showExitWarningDialog(context, pomodoroState);
          if (shouldExit) {
            SystemNavigator.pop();
          }
        } else {
          // No active session, allow normal exit
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: _selectedIndex == 0
            ? AppBar(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.watch_later_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'TimeWarden',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                elevation: 0,
                scrolledUnderElevation: 1,
                backgroundColor: theme.colorScheme.surface,
                surfaceTintColor: Colors.transparent,
              )
            : null,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            DashboardHomeTab(onNavigateToTab: _onNavigateToTab),
            const HabitsPage(),
            const PomodoroPage(),
            const SecureJournalPage(),
            const SettingsPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            HapticService.navigationTap();
            setState(() {
              _selectedIndex = index;
            });
            _saveSelectedTab(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Habits',
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'Pomodoro',
            ),
            NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag),
              label: 'Goals',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ), // Close PopScope child (Scaffold)
    ); // Close PopScope
  }

  Future<bool> _showExitWarningDialog(
      BuildContext context, PomodoroState pomodoroState) async {
    String sessionType = 'Session';
    String timeRemaining = '';

    if (pomodoroState is PomodoroRunning) {
      sessionType = pomodoroState.currentSession.displayType;
      final remaining = pomodoroState.currentSession.remainingSeconds;
      final minutes = remaining ~/ 60;
      final seconds = remaining % 60;
      timeRemaining =
          '${minutes}:${seconds.toString().padLeft(2, '0')} remaining';
    } else if (pomodoroState is PomodoroPaused) {
      sessionType = pomodoroState.currentSession.displayType;
      timeRemaining = 'Currently paused';
    }

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: Icon(
                Icons.timer_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                '$sessionType is Running!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeRemaining,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Are you sure you want to close TimeWarden?\n\nYour session will be paused and can be resumed when you return.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Keep Running',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Pause the session if it's running
                    if (pomodoroState is PomodoroRunning) {
                      context
                          .read<PomodoroBloc>()
                          .add(const PomodoroPauseRequested());
                    }
                    Navigator.of(context).pop(true);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  child: const Text(
                    'Close App',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class DashboardHomeTab extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const DashboardHomeTab({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab>
    with AutomaticKeepAliveClientMixin {
  UserStats? _userStats;
  late UserStatsRepositoryImpl _statsRepository;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _statsRepository = UserStatsRepositoryImpl(FirebaseService());

    // Load data using BLoCs from context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitsBloc>().add(HabitsLoadRequested());
      context.read<JournalBloc>().add(const JournalLoadRequested());
      context.read<GoalBloc>().add(GoalLoadRequested());
      _loadUserStats();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh all data when the widget becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HabitsBloc>().add(HabitsLoadRequested());
        _loadUserStats();
      }
    });
  }

  Future<void> _loadUserStats() async {
    final userId = FirebaseService().currentUserId;
    if (userId != null) {
      final stats = await _statsRepository.getUserStats(userId);
      if (mounted) {
        setState(() {
          _userStats = stats;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return BlocListener<HabitsBloc, HabitsState>(
      listener: (context, state) {
        // Reload stats whenever habits state changes (completion, points adjustment, etc.)
        if (state is HabitsLoaded) {
          _loadUserStats();
        }
      },
      child: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data when user pulls to refresh
          context.read<HabitsBloc>().add(HabitsLoadRequested());
          context.read<JournalBloc>().add(const JournalLoadRequested());
          context.read<GoalBloc>().add(GoalLoadRequested());
          await _loadUserStats();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Quote card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Quote of the Day',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDailyQuote(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick stats
              BlocBuilder<HabitsBloc, HabitsState>(
                builder: (context, habitsState) {
                  return BlocBuilder<GoalBloc, GoalState>(
                    builder: (context, goalState) {
                      // Calculate stats from real data
                      int totalHabits = 0;
                      int completedHabits = 0;
                      int pendingGoals = 0;
                      int currentStreak =
                          _userStats?.perfectDays ?? 0; // Use backend stats

                      if (habitsState is HabitsLoaded) {
                        // Count all habits that should be done today (active habits)
                        // Include all habits that haven't met their period target OR are daily habits
                        final activeHabitsForToday =
                            habitsState.habits.where((habit) {
                          // Always include daily habits
                          if (habit.frequency.type ==
                              HabitFrequencyType.daily) {
                            return true;
                          }
                          // For other frequencies, include if not completed for period
                          return !habit.isCompletedForCurrentPeriod;
                        }).toList();

                        totalHabits = activeHabitsForToday.length;
                        completedHabits = activeHabitsForToday.where((habit) {
                          return habit.isCompletedToday;
                        }).length;

                        // Perfect days now tracked automatically in habits BLoC
                      }

                      if (goalState is GoalLoaded) {
                        pendingGoals = goalState.goals
                            .where((goal) => !goal.isCompleted)
                            .length;
                      } else if (goalState is GoalOperationSuccess) {
                        pendingGoals = goalState.goals
                            .where((goal) => !goal.isCompleted)
                            .length;
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    HapticService.buttonTap();
                                    widget.onNavigateToTab(
                                        1); // Navigate to Habits tab
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildStatCard(
                                    context,
                                    'Today\'s Habits',
                                    '$completedHabits/$totalHabits',
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: BlocBuilder<PomodoroBloc, PomodoroState>(
                                  builder: (context, pomodoroState) {
                                    return _buildPomodoroStatCard(
                                        context, pomodoroState);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    HapticService.buttonTap();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PerfectDaysHeatmapPage(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildStatCard(
                                    context,
                                    'Perfect Days',
                                    '$currentStreak days',
                                    Icons.local_fire_department,
                                    Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    HapticService.buttonTap();
                                    widget.onNavigateToTab(
                                        3); // Navigate to Goals tab
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildStatCard(
                                    context,
                                    'Goals Pending',
                                    '$pendingGoals',
                                    Icons.flag,
                                    Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Today's habits section - Quick Stats Summary
              Text(
                'Today\'s Habits',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              BlocBuilder<HabitsBloc, HabitsState>(
                builder: (context, state) {
                  if (state is HabitsLoading) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (state is HabitsLoaded) {
                    return _buildHabitsQuickSummary(context, state);
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error loading habits',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ), // Close SingleChildScrollView (child of RefreshIndicator)
      ), // Close RefreshIndicator
    ); // Close BlocListener
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPomodoroStatCard(
      BuildContext context, PomodoroState pomodoroState) {
    String title = 'Today\'s Points';
    String value = '0';

    // Get today's points from user stats
    final totalPoints = _userStats?.totalPointsToday ?? 0;

    // Check if unlimited mode (all active habits completed)
    final habitsState = context.watch<HabitsBloc>().state;
    bool isUnlimited = false;
    if (habitsState is HabitsLoaded) {
      isUnlimited = habitsState.habits.where((h) => h.isActive).every((h) =>
          h.frequency.type == HabitFrequencyType.daily
              ? h.isCompletedToday
              : h.isCompletedForCurrentPeriod);

      // Only show unlimited if there are active habits
      if (habitsState.habits.where((h) => h.isActive).isEmpty) {
        isUnlimited = false;
      }
    }

    value = isUnlimited ? '∞' : totalPoints.toString();

    return Card(
      child: InkWell(
        onTap: () async {
          HapticService.buttonTap();
          await showDialog(
            context: context,
            builder: (context) => BlocProvider.value(
              value: context.read<HabitsBloc>(),
              child: const PointsDetailDialog(),
            ),
          );
          // Reload habits to refresh points after dialog closes
          if (context.mounted) {
            context.read<HabitsBloc>().add(HabitsLoadRequested());
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyQuote() {
    final quote = QuotesService.getQuoteOfTheDay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${quote.text}"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '— ${quote.author}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let this inspire your day!',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildHabitsQuickSummary(BuildContext context, HabitsLoaded state) {
    if (state.habits.isEmpty) {
      return _buildEmptyHabitsState(context);
    }

    final today = DateTime.now();
    final activeHabitsForToday = _getActiveHabitsForToday(state.habits);
    final completedHabits =
        activeHabitsForToday.where((h) => h.isCompletedToday).toList();
    final incompleteHabits =
        activeHabitsForToday.where((h) => !h.isCompletedToday).toList();

    final totalHabits = activeHabitsForToday.length;
    final completedCount = completedHabits.length;
    final progress = totalHabits > 0 ? completedCount / totalHabits : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressHeader(
                context, completedCount, totalHabits, progress),
            if (totalHabits > 0) ...[
              const SizedBox(height: 16),
              _buildPerfectDayBanner(
                  context, progress, incompleteHabits.length),
            ],
            if (incompleteHabits.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildRemainingHabitsSection(context, incompleteHabits, today),
            ],
            if (completedHabits.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCompletedHabitsSection(context, completedHabits),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHabitsState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No habits yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Start building better habits today!',
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

  List<Habit> _getActiveHabitsForToday(List<Habit> habits) {
    return habits.where((habit) {
      if (habit.frequency.type == HabitFrequencyType.daily) {
        return true;
      }
      return !habit.isCompletedForCurrentPeriod;
    }).toList();
  }

  Widget _buildProgressHeader(
    BuildContext context,
    int completedCount,
    int totalHabits,
    double progress,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$completedCount of $totalHabits completed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}% complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Icon(
                progress == 1.0 ? Icons.check : Icons.track_changes,
                size: 20,
                color: progress == 1.0
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerfectDayBanner(
    BuildContext context,
    double progress,
    int remainingCount,
  ) {
    final isPerfectDay = progress == 1.0;
    final backgroundColor = isPerfectDay
        ? Theme.of(context).colorScheme.tertiaryContainer
        : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3);
    final textColor = isPerfectDay
        ? Theme.of(context).colorScheme.onTertiaryContainer
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isPerfectDay
                ? Icons.local_fire_department
                : Icons.local_fire_department_outlined,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isPerfectDay
                  ? 'Perfect Day Achieved! 🎉'
                  : 'Complete $remainingCount more for a perfect day!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingHabitsSection(
    BuildContext context,
    List<Habit> incompleteHabits,
    DateTime today,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remaining (${incompleteHabits.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        ...incompleteHabits.take(3).map(
              (habit) => _buildHabitRow(context, habit, today, false),
            ),
        if (incompleteHabits.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${incompleteHabits.length - 3} more',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompletedHabitsSection(
    BuildContext context,
    List<Habit> completedHabits,
  ) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        'Completed (${completedHabits.length})',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.tertiary,
            ),
      ),
      children: completedHabits.map((habit) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHabitRow(
    BuildContext context,
    Habit habit,
    DateTime today,
    bool isCompleted,
  ) {
    final streak = habit.currentStreak;
    final points = habit.pointsValue ?? 0;

    return InkWell(
      onTap: isCompleted
          ? null
          : () {
              HapticService.buttonTap();
              context.read<HabitsBloc>().add(
                    HabitCompletionToggled(habitId: habit.id, date: today),
                  );
            },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (!isCompleted && (streak > 0 || points > 0))
                    Row(
                      children: [
                        if (streak > 0) ...[
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$streak day${streak > 1 ? 's' : ''}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                        if (streak > 0 && points > 0) const SizedBox(width: 8),
                        if (points > 0) ...[
                          Icon(
                            Icons.stars,
                            size: 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${points.toStringAsFixed(0)} pts',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            if (!isCompleted)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
