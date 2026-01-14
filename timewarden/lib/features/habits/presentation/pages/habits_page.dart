import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habits_bloc.dart';
import '../widgets/calendar_habits_view.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/points_detail_dialog.dart';
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
  bool _hideCompletedHabits = true; // Default to hiding completed habits

  @override
  void initState() {
    super.initState();
    _loadHideCompletedSetting();
  }

  Future<void> _loadHideCompletedSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hideCompletedHabits = prefs.getBool('hide_completed_habits') ?? true;
    });
  }

  Future<void> _saveHideCompletedSetting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_completed_habits', _hideCompletedHabits);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          BlocBuilder<HabitsBloc, HabitsState>(
            builder: (context, state) {
              final points =
                  state is HabitsLoaded ? state.totalPointsToday : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: InkWell(
                  onTap: () async {
                    HapticService.buttonTap();
                    await showDialog(
                      context: context,
                      builder: (dialogContext) => BlocProvider.value(
                        value: context.read<HabitsBloc>(),
                        child: const PointsDetailDialog(),
                      ),
                    );
                    // Reload habits to refresh points after dialog closes
                    if (context.mounted) {
                      context.read<HabitsBloc>().add(HabitsLoadRequested());
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars,
                          size: 20,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          points.toStringAsFixed(1),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              HapticService.selectionClick();
              switch (value) {
                case 'toggle_hide_completed':
                  setState(() {
                    _hideCompletedHabits = !_hideCompletedHabits;
                  });
                  _saveHideCompletedSetting();
                  // Reload habits from Firebase
                  context.read<HabitsBloc>().add(HabitsLoadRequested());
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'toggle_hide_completed',
                child: Row(
                  children: [
                    Icon(
                      _hideCompletedHabits
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hideCompletedHabits
                                ? 'Show Completed Habits'
                                : 'Hide Completed Habits',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            _hideCompletedHabits
                                ? 'Show habits completed in current period'
                                : 'Hide habits completed in current period',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    print('\n🔍 FILTERING HABITS - hideCompletedHabits: $_hideCompletedHabits');
    print('   Total habits: ${allHabits.length}');

    List<Habit> displayHabits = allHabits;
    if (_hideCompletedHabits) {
      displayHabits = allHabits.where((habit) {
        // Hide habits that are completed for the current period
        // This includes habits with green checkmarks (completed today) and
        // habits with purple indicators (completed for period but not today)
        final shouldShow = !habit.isCompletedForCurrentPeriod;
        print(
            '   Habit "${habit.name}": isCompletedForCurrentPeriod=${habit.isCompletedForCurrentPeriod}, shouldShow=$shouldShow');
        return shouldShow;
      }).toList();
    }

    print('   Filtered habits: ${displayHabits.length}');
    print('   Showing: ${displayHabits.map((h) => h.name).join(", ")}\n');

    return CalendarHabitsView(
      habits: displayHabits,
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
}
