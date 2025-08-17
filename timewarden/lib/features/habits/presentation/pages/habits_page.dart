import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_filter.dart';
import '../bloc/habits_bloc.dart';
import '../widgets/habit_card.dart';
import '../widgets/calendar_habits_view.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/widgets/animations.dart';
import 'add_edit_habit_page.dart';
import 'habit_detail_page.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  @override
  void initState() {
    super.initState();
    // Trigger the load event after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitsBloc>().add(HabitsLoadRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HabitsView();
  }
}

class HabitsView extends StatefulWidget {
  const HabitsView({super.key});

  @override
  State<HabitsView> createState() => _HabitsViewState();
}

class _HabitsViewState extends State<HabitsView> {
  HabitFilter _currentFilter = HabitFilter.all;
  bool _isCalendarView = true; // Default to calendar view
  bool _hideCompletedHabits = false; // Track hide completed setting

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              HapticService.buttonTap();
              Provider.of<ThemeService>(context, listen: false).toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          AnimatedScaleButton(
            onTap: () {
              HapticService.buttonTap();
              setState(() {
                _isCalendarView = !_isCalendarView;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                  _isCalendarView ? Icons.view_list : Icons.calendar_view_week),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              HapticService.buttonTap();
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: BlocConsumer<HabitsBloc, HabitsState>(
        listener: (context, state) {
          if (state is HabitsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HabitsLoading || state is HabitsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HabitsLoaded) {
            if (state.habits.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildHabitsView(context, state.habits);
          }

          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
      floatingActionButton: SlideInAnimation(
        begin: const Offset(0, 1.0),
        delay: const Duration(milliseconds: 400),
        child: FloatingActionButton(
          onPressed: () {
            HapticService.buttonTap();
            _navigateToAddHabit(context);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildHabitsView(BuildContext context, List<Habit> allHabits) {
    // Filter habits based on hide completed setting
    List<Habit> displayHabits = allHabits;
    if (_isCalendarView && _hideCompletedHabits) {
      final today = DateTime.now();
      displayHabits = allHabits.where((habit) {
        // Check if habit is completed today
        final isCompletedToday = habit.completedDates.any((date) =>
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day);
        return !isCompletedToday;
      }).toList();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      child: _isCalendarView
          ? CalendarHabitsView(
              key: ValueKey(
                  'calendar_${displayHabits.length}_$_hideCompletedHabits'),
              habits: displayHabits,
            )
          : _buildListView(allHabits),
    );
  }

  Widget _buildListView(List<Habit> allHabits) {
    // List view with filters
    final filteredHabits =
        HabitFilterService.filterHabits(allHabits, _currentFilter);

    return SlideInAnimation(
      key: const ValueKey('list'),
      child: Column(
        children: [
          // Filter tabs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab(
                    'All',
                    HabitFilter.all,
                    allHabits.length,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterTab(
                    'Pending',
                    HabitFilter.pending,
                    HabitFilterService.filterHabits(
                            allHabits, HabitFilter.pending)
                        .length,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterTab(
                    'Completed',
                    HabitFilter.completed,
                    HabitFilterService.filterHabits(
                            allHabits, HabitFilter.completed)
                        .length,
                  ),
                ),
              ],
            ),
          ),

          // Habits list
          Expanded(
            child: _buildHabitsList(context, filteredHabits),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, HabitFilter filter, int count) {
    final isSelected = _currentFilter == filter;

    return AnimatedScaleButton(
      onTap: () {
        HapticService.buttonTap();
        setState(() {
          _currentFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text('$title ($count)'),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No habits yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first habit to start building better routines',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _navigateToAddHabit(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Habit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsList(BuildContext context, List<Habit> habits) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<HabitsBloc>().add(HabitsLoadRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: habits.length,
        itemBuilder: (context, index) {
          final habit = habits[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HabitCard(
              habit: habit,
              onTap: () => _navigateToHabitDetail(context, habit),
              onToggleCompletion: () {
                context.read<HabitsBloc>().add(
                      HabitCompletionToggled(
                        habitId: habit.id,
                        date: DateTime.now(),
                      ),
                    );
              },
            ),
          );
        },
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'View Options',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Hide completed option (only show in calendar view)
            if (_isCalendarView) ...[
              ListTile(
                leading: Icon(
                  _hideCompletedHabits
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  _hideCompletedHabits
                      ? 'Show Completed Habits'
                      : 'Hide Completed Habits',
                ),
                subtitle: Text(
                  _hideCompletedHabits
                      ? 'Show habits completed today'
                      : 'Hide habits completed today',
                ),
                onTap: () {
                  HapticService.selectionClick();
                  setState(() {
                    _hideCompletedHabits = !_hideCompletedHabits;
                  });
                  Navigator.pop(context);
                },
              ),
            ],

            // Add more options here in the future
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _navigateToAddHabit(BuildContext context) {
    HapticService.buttonTap();
    // Get the BLoC reference before navigating
    final habitsBloc = context.read<HabitsBloc>();

    Navigator.of(context).push(
      CustomPageRoute(
        child: BlocProvider.value(
          value: habitsBloc,
          child: const AddEditHabitPage(),
        ),
      ),
    );
  }

  void _navigateToHabitDetail(BuildContext context, Habit habit) {
    HapticService.buttonTap();
    // Get the BLoC reference before navigating
    final habitsBloc = context.read<HabitsBloc>();

    Navigator.of(context).push(
      CustomPageRoute(
        child: BlocProvider.value(
          value: habitsBloc,
          child: HabitDetailPage(habit: habit),
        ),
      ),
    );
  }

  void _navigateToEditHabit(BuildContext context, Habit habit) {
    // Get the BLoC reference before navigating
    final habitsBloc = context.read<HabitsBloc>();

    Navigator.of(context).push(
      CustomPageRoute(
        child: BlocProvider.value(
          value: habitsBloc,
          child: AddEditHabitPage(habit: habit),
        ),
      ),
    );
  }
}
