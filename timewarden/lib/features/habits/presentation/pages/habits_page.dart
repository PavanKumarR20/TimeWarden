import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_filter.dart';
import '../bloc/habits_bloc.dart';
import '../widgets/habit_card.dart';
import 'add_edit_habit_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddHabit(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHabitsView(BuildContext context, List<Habit> allHabits) {
    final filteredHabits =
        HabitFilterService.filterHabits(allHabits, _currentFilter);

    return Column(
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
    );
  }

  Widget _buildFilterTab(String title, HabitFilter filter, int count) {
    final isSelected = _currentFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: Container(
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
          child: Text(
            '$title ($count)',
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
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
              onTap: () => _navigateToEditHabit(context, habit),
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

  void _navigateToAddHabit(BuildContext context) {
    // Get the BLoC reference before navigating
    final habitsBloc = context.read<HabitsBloc>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: habitsBloc,
          child: const AddEditHabitPage(),
        ),
      ),
    );
  }

  void _navigateToEditHabit(BuildContext context, Habit habit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<HabitsBloc>(),
          child: AddEditHabitPage(habit: habit),
        ),
      ),
    );
  }
}
