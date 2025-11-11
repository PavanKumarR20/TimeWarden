import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../habits/presentation/pages/habits_page.dart';
import '../../../habits/presentation/bloc/habits_bloc.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../pomodoro/presentation/pages/pomodoro_page.dart';
import '../../../pomodoro/presentation/pages/pomodoro_statistics_page.dart';
import '../../../pomodoro/presentation/bloc/pomodoro_bloc.dart';
import '../../../pomodoro/presentation/bloc/pomodoro_state.dart';
import '../../../pomodoro/presentation/bloc/pomodoro_event.dart';
import '../../../pomodoro/domain/entities/pomodoro_session.dart';
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
    // Refresh stats when the widget becomes visible again
    _loadUserStats();
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
    return RefreshIndicator(
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                        if (habit.frequency.type == HabitFrequencyType.daily) {
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
                              child: _buildStatCard(
                                context,
                                'Today\'s Habits',
                                '$completedHabits/$totalHabits',
                                Icons.check_circle,
                                Colors.green,
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
                              child: _buildStatCard(
                                context,
                                'Goals Pending',
                                '$pendingGoals',
                                Icons.flag,
                                Colors.blue,
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

            // Today's habits section
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
                  if (state.habits.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No habits yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the Habits tab to create your first habit!',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Show today's incomplete habits only (excluding habits completed for period)
                  final today = DateTime.now();
                  final incompleteHabits = state.habits
                      .where((habit) {
                        // Exclude habits that are completed for the current period
                        if (habit.isCompletedForCurrentPeriod) {
                          return false;
                        }

                        final isCompletedToday = habit.completedDates.any(
                            (date) =>
                                date.year == today.year &&
                                date.month == today.month &&
                                date.day == today.day);
                        return !isCompletedToday; // Only show incomplete habits
                      })
                      .take(3)
                      .toList();

                  if (incompleteHabits.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.celebration,
                              size: 64,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'All habits completed! 🎉',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Great job staying disciplined!',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: incompleteHabits.map((habit) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.circle_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(habit.name),
                          subtitle: const Text('Tap to complete'),
                          onTap: () async {
                            // Complete the habit
                            context.read<HabitsBloc>().add(
                                HabitCompletionToggled(
                                    habitId: habit.id, date: today));

                            // Show feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${habit.name} completed! 🎉'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
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
            ), // Add this comma for the habits section
          ],
        ),
      ), // Close SingleChildScrollView (child of RefreshIndicator)
    ); // Close RefreshIndicator
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
    String title = 'Focus Time';
    String value = '0m';

    // Get all-time focus time from user stats
    final totalPomodoroSessions = _userStats?.totalPomodoroSessions ?? 0;

    // Estimate total minutes: each session is typically 25 minutes (can be adjusted)
    // This is an estimation since we track session count, not exact minutes
    int estimatedMinutes = totalPomodoroSessions * 25;

    // If we have current running/paused session, add its progress
    if (pomodoroState is PomodoroRunning) {
      if (pomodoroState.currentSession.type == PomodoroType.work) {
        final totalDuration =
            Duration(minutes: pomodoroState.settings.workDurationMinutes);
        final completedTime =
            totalDuration - pomodoroState.currentSession.remainingTime;
        estimatedMinutes += completedTime.inMinutes;
      }
    } else if (pomodoroState is PomodoroPaused) {
      if (pomodoroState.currentSession.type == PomodoroType.work) {
        final totalDuration =
            Duration(minutes: pomodoroState.settings.workDurationMinutes);
        final completedTime =
            totalDuration - pomodoroState.currentSession.remainingTime;
        estimatedMinutes += completedTime.inMinutes;
      }
    }

    // Format the time
    if (estimatedMinutes >= 60) {
      final hours = estimatedMinutes ~/ 60;
      final minutes = estimatedMinutes % 60;
      if (minutes > 0) {
        value = '${hours}h ${minutes}m';
      } else {
        value = '${hours}h';
      }
    } else {
      value = '${estimatedMinutes}m';
    }

    return Card(
      child: InkWell(
        onTap: () {
          HapticService.buttonTap();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: context.read<PomodoroBloc>(),
                child: const PomodoroStatisticsPage(),
              ),
            ),
          );
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

  Future<void> _checkAndUpdatePerfectDay(
      List<Habit> habits, int totalHabits, int completedHabits) async {
    final userId = FirebaseService().currentUserId;
    if (userId == null || totalHabits == 0) {
      print(
          'DEBUG: Skipping perfect day check - userId: $userId, totalHabits: $totalHabits');
      return;
    }

    // Check if today is a perfect day (all habits completed)
    final isCurrentlyPerfect = completedHabits == totalHabits;
    print(
        'DEBUG: Perfect day check - completed: $completedHabits/$totalHabits, isPerfect: $isCurrentlyPerfect');

    try {
      // Get current stats to see what we're working with
      final currentStats = await _statsRepository.getUserStats(userId);
      print(
          'DEBUG: Current perfect days in backend: ${currentStats?.perfectDays ?? 0}');

      if (isCurrentlyPerfect) {
        // Check if today's perfect day was already counted
        final todayAlreadyCounted =
            await _isTodayAlreadyCountedAsPerfect(userId);
        print('DEBUG: Today already counted as perfect: $todayAlreadyCounted');

        if (!todayAlreadyCounted) {
          await _statsRepository.incrementPerfectDays(userId);
          await _markTodayAsPerfectDayCounted(userId);
          await _loadUserStats(); // Refresh stats
          print(
              '✅ Perfect day incremented! New total: ${_userStats?.perfectDays}');
        }
      }
    } catch (e) {
      print('❌ Error updating perfect days: $e');
    }
  }

  Future<bool> _isTodayAlreadyCountedAsPerfect(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key =
        'perfect_day_counted_${userId}_${today.year}_${today.month}_${today.day}';
    return prefs.getBool(key) ?? false;
  }

  Future<void> _markTodayAsPerfectDayCounted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key =
        'perfect_day_counted_${userId}_${today.year}_${today.month}_${today.day}';
    await prefs.setBool(key, true);
  }

  bool _wasPerfectDayAlready(List<Habit> habits) {
    // Check if all habits that exist were already completed today
    // This helps us detect when a perfect day is lost vs gained
    final today = DateTime.now();
    for (final habit in habits) {
      final wasCompleted = habit.completedDates.any((date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day);
      if (!wasCompleted) return false;
    }
    return habits.isNotEmpty;
  }

  /// Calculates total number of days where all habits were completed
  /// These are "Days of Discipline" - when commitment met action
  /// A testament to self-control and consistency in personal growth
  int _calculateDailyCompletionStreak(List<Habit> habits) {
    if (habits.isEmpty) return 0;

    int perfectDays = 0;

    // Get all unique dates where any habit was completed
    Set<DateTime> allCompletionDates = {};
    for (final habit in habits) {
      for (final date in habit.completedDates) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        allCompletionDates.add(dateOnly);
      }
    }

    // Always include today in the check (important for current day completions)
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    allCompletionDates.add(todayOnly);

    // For each date, check if ALL habits were completed
    for (final date in allCompletionDates) {
      // Get habits that were active on this date (existed and should be done)
      final activeHabitsOnDate = habits.where((habit) {
        // Check if habit existed on this date (created before or on this date)
        return habit.createdAt.isBefore(date.add(const Duration(days: 1)));
      }).toList();

      if (activeHabitsOnDate.isEmpty) continue;

      bool allHabitsCompletedOnDate = true;
      for (final habit in activeHabitsOnDate) {
        // Check if this habit was completed on this date
        bool habitCompletedOnDate = habit.completedDates.any((completedDate) =>
            completedDate.year == date.year &&
            completedDate.month == date.month &&
            completedDate.day == date.day);

        if (!habitCompletedOnDate) {
          allHabitsCompletedOnDate = false;
          break;
        }
      }

      if (allHabitsCompletedOnDate) {
        perfectDays++;
      }
    }

    return perfectDays;
  }
}
