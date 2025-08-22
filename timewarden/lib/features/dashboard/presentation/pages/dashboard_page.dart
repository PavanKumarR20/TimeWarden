import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../habits/presentation/pages/habits_page.dart';
import '../../../habits/presentation/bloc/habits_bloc.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../pomodoro/presentation/pages/pomodoro_page.dart';
import '../../../pomodoro/presentation/bloc/pomodoro_bloc.dart';
import '../../../pomodoro/presentation/bloc/pomodoro_state.dart';
import '../../../pomodoro/domain/entities/pomodoro_session.dart';
import '../../../journal/presentation/bloc/journal_bloc.dart';
import '../../../journal/presentation/bloc/journal_event.dart';
import '../../../journal/presentation/bloc/journal_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../secure_journal_page.dart';
import '../../../../core/services/quotes_service.dart';

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

  List<Widget> get _pages => [
        DashboardHomeTab(onNavigateToTab: _onNavigateToTab),
        const HabitsPage(),
        const PomodoroPage(),
        const SecureJournalPage(),
        const SettingsPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeWarden'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
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
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
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

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  @override
  void initState() {
    super.initState();

    // Load data using BLoCs from context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitsBloc>().add(HabitsLoadRequested());
      context.read<JournalBloc>().add(const JournalLoadRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              return BlocBuilder<JournalBloc, JournalState>(
                builder: (context, journalState) {
                  // Calculate stats from real data
                  int totalHabits = 0;
                  int completedHabits = 0;
                  int journalEntries = 0;
                  int currentStreak = 0;

                  if (habitsState is HabitsLoaded) {
                    totalHabits = habitsState.habits.length;
                    final today = DateTime.now();
                    completedHabits = habitsState.habits.where((habit) {
                      return habit.completedDates.any((date) =>
                          date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day);
                    }).length;

                    // Calculate daily completion streak - only counts days where ALL habits were completed
                    if (habitsState.habits.isNotEmpty) {
                      currentStreak =
                          _calculateDailyCompletionStreak(habitsState.habits);
                    }
                  }

                  if (journalState is JournalLoaded) {
                    journalEntries = journalState.entries.length;
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
                            child: _buildStatCard(
                              context,
                              'Days of Discipline',
                              '$currentStreak days',
                              Icons.local_fire_department,
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Journal Entries',
                              '$journalEntries',
                              Icons.book,
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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

                // Show today's incomplete habits only
                final today = DateTime.now();
                final incompleteHabits = state.habits
                    .where((habit) {
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
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                        subtitle: Text(habit.description?.isNotEmpty == true
                            ? habit.description!
                            : 'Tap to complete'),
                        onTap: () async {
                          // Complete the habit
                          context.read<HabitsBloc>().add(HabitCompletionToggled(
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
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

    // Calculate total completed work time
    if (pomodoroState is PomodoroReady ||
        pomodoroState is PomodoroRunning ||
        pomodoroState is PomodoroPaused) {
      int totalMinutes = 0;

      if (pomodoroState is PomodoroReady) {
        totalMinutes = pomodoroState.completedWorkSessions *
            pomodoroState.settings.workDurationMinutes;
      } else if (pomodoroState is PomodoroRunning) {
        totalMinutes = pomodoroState.completedWorkSessions *
            pomodoroState.settings.workDurationMinutes;
        // Add current session's completed time if it's a work session
        if (pomodoroState.currentSession.type == PomodoroType.work) {
          final totalDuration =
              Duration(minutes: pomodoroState.settings.workDurationMinutes);
          final completedTime =
              totalDuration - pomodoroState.currentSession.remainingTime;
          totalMinutes += completedTime.inMinutes;
        }
      } else if (pomodoroState is PomodoroPaused) {
        totalMinutes = pomodoroState.completedWorkSessions *
            pomodoroState.settings.workDurationMinutes;
        // Add current session's completed time if it's a work session
        if (pomodoroState.currentSession.type == PomodoroType.work) {
          final totalDuration =
              Duration(minutes: pomodoroState.settings.workDurationMinutes);
          final completedTime =
              totalDuration - pomodoroState.currentSession.remainingTime;
          totalMinutes += completedTime.inMinutes;
        }
      }

      if (totalMinutes >= 60) {
        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;
        if (minutes > 0) {
          value = '${hours}h ${minutes}m';
        } else {
          value = '${hours}h';
        }
      } else {
        value = '${totalMinutes}m';
      }
    }

    return Card(
      child: InkWell(
        onTap: () {
          widget.onNavigateToTab(2); // Navigate to Pomodoro tab
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

    // For each date, check if ALL habits were completed
    for (final date in allCompletionDates) {
      bool allHabitsCompletedOnDate = true;

      for (final habit in habits) {
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
