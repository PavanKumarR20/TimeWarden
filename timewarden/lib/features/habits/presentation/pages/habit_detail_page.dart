import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habits_bloc.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/services/haptic_service.dart';
import 'add_edit_habit_page.dart';

class HabitDetailPage extends StatelessWidget {
  final Habit habit;

  const HabitDetailPage({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitsBloc, HabitsState>(
      builder: (context, state) {
        // Get the most current habit data from the state
        Habit currentHabit = habit;
        if (state is HabitsLoaded) {
          final updatedHabit = state.habits.firstWhere(
            (h) => h.id == habit.id,
            orElse: () => habit,
          );
          currentHabit = updatedHabit;
        }

        Color habitColor;
        try {
          habitColor = currentHabit.color != null
              ? Color(int.parse(
                  currentHabit.color!.replaceAll('#', '').padLeft(8, 'FF'),
                  radix: 16))
              : Theme.of(context).colorScheme.primary;
        } catch (e) {
          habitColor = Theme.of(context).colorScheme.primary;
        }

        return BlocListener<HabitsBloc, HabitsState>(
          listener: (context, state) {
            if (state is HabitsLoaded) {
              // Check if the current habit was deleted
              final habitExists = state.habits.any((h) => h.id == habit.id);
              if (!habitExists) {
                // Habit was deleted, navigate back to habits page
                Navigator.of(context).pop();
              }
            }
          },
          child: _buildScaffold(context, currentHabit, habitColor),
        );
      },
    );
  }

  Widget _buildScaffold(
      BuildContext context, Habit currentHabit, Color habitColor) {
    return Scaffold(
      backgroundColor: habitColor,
      appBar: AppBar(
        backgroundColor: habitColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          currentHabit.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _navigateToEditHabit(context, currentHabit),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _showDeleteConfirmation(context, currentHabit),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section with habit question and details
          Container(
            width: double.infinity,
            color: habitColor,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main question
                Text(
                  'Did you ${currentHabit.name.toLowerCase()} today?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Frequency info
                Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentHabit.frequency.displayText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content section (scrollable)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentHabit.notes != null &&
                                currentHabit.notes!.isNotEmpty) ...[
                              _buildNotesSection(context, currentHabit),
                              const SizedBox(height: 32),
                            ],
                            _buildStatsSection(context, currentHabit),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, Habit currentHabit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            currentHabit.notes!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, Habit currentHabit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Current Streak',
                '${currentHabit.currentStreak}',
                Icons.local_fire_department,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Best Streak',
                '${currentHabit.longestStreak}',
                Icons.star,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToEditHabit(BuildContext context, Habit currentHabit) {
    HapticService.lightImpact();
    Navigator.of(context).push(
      CustomPageRoute(
        child: BlocProvider.value(
          value: context.read<HabitsBloc>(),
          child: AddEditHabitPage(habit: currentHabit),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Habit currentHabit) {
    HapticService.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Habit'),
          content: Text(
              'Are you sure you want to delete "${currentHabit.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<HabitsBloc>().add(HabitDeleted(currentHabit.id));
                HapticService.heavyImpact();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
