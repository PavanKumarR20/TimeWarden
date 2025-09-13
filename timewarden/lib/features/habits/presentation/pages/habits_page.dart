import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habits_bloc.dart';
import '../widgets/calendar_habits_view.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/widgets/animations.dart';
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
    if (_hideCompletedHabits) {
      displayHabits = allHabits.where((habit) {
        // Only hide habits that are completed TODAY, not just completed for the period
        // This allows habits completed for the period (purple state) to remain visible
        return !habit.isCompletedToday;
      }).toList();
    }

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

            // Hide completed option
            ListTile(
              leading: Icon(
                _hideCompletedHabits ? Icons.visibility_off : Icons.visibility,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                _hideCompletedHabits
                    ? 'Show Completed Habits'
                    : 'Hide Completed Habits',
              ),
              subtitle: Text(
                _hideCompletedHabits
                    ? 'Show habits completed in current period'
                    : 'Hide habits completed in current period',
              ),
              onTap: () {
                HapticService.selectionClick();
                setState(() {
                  _hideCompletedHabits = !_hideCompletedHabits;
                });
                _saveHideCompletedSetting();
                Navigator.pop(context);
              },
            ),

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
}
