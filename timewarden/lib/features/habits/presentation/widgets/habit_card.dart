import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habits_bloc.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/services/haptic_service.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onTap;
  final VoidCallback? onToggleCompletion;

  const HabitCard({
    super.key,
    required this.habit,
    this.onTap,
    this.onToggleCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.isCompletedForCurrentPeriod;
    Color habitColor;
    try {
      habitColor = habit.color != null
          ? Color(int.parse(habit.color!.replaceAll('#', '').padLeft(8, 'FF'),
              radix: 16))
          : Theme.of(context).colorScheme.primary;
    } catch (e) {
      habitColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8), // Reduced from 12 to 8
          child: Row(
            children: [
              // Icon and completion status
              BlocBuilder<HabitsBloc, HabitsState>(
                buildWhen: (previous, current) {
                  if (previous is HabitsLoaded && current is HabitsLoaded) {
                    final prevHabit = previous.habits.firstWhere(
                      (h) => h.id == habit.id,
                      orElse: () => habit,
                    );
                    final currHabit = current.habits.firstWhere(
                      (h) => h.id == habit.id,
                      orElse: () => habit,
                    );
                    return prevHabit.isCompletedForCurrentPeriod !=
                        currHabit.isCompletedForCurrentPeriod;
                  }
                  return false;
                },
                builder: (context, state) {
                  final currentHabit = state is HabitsLoaded
                      ? state.habits.firstWhere((h) => h.id == habit.id,
                          orElse: () => habit)
                      : habit;
                  final isCurrentlyCompleted =
                      currentHabit.isCompletedForCurrentPeriod;

                  return AnimatedScaleButton(
                    onTap: () {
                      HapticService.buttonTap();
                      onToggleCompletion?.call();
                    },
                    child: SizedBox(
                      width: 32, // Reduced from 40 to 32
                      height: 32, // Reduced from 40 to 32
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isCurrentlyCompleted
                              ? Container(
                                  key: ValueKey('completed'),
                                  width: 24, // Reduced from 28 to 24
                                  height: 24, // Reduced from 28 to 24
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(
                                            0xFF059669) // Darker green for dark mode
                                        : const Color(
                                            0xFF10B981), // Brighter green for light mode
                                    borderRadius: BorderRadius.circular(
                                        12), // Reduced from 14 to 12
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16, // Reduced from 18 to 16
                                  ),
                                )
                              : Container(
                                  key: ValueKey('incomplete'),
                                  width: 24, // Reduced from 28 to 24
                                  height: 24, // Reduced from 28 to 24
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(
                                              0xFF4B5563) // Better contrast for dark mode
                                          : const Color(
                                              0xFFD1D5DB), // Light gray for light mode
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        12), // Reduced from 14 to 12
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8), // Reduced from 12 to 8

              // Habit details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : null,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (habit.description != null &&
                        habit.description!.isNotEmpty) ...[
                      const SizedBox(height: 1), // Reduced from 2 to 1
                      Text(
                        habit.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 11, // Reduced from 12 to 11
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4), // Reduced from 6 to 4
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 12, // Reduced from 14 to 12
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3), // Reduced from 4 to 3
                        Text(
                          habit.frequency.displayText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const Spacer(),
                        if (habit.currentStreak > 0) ...[
                          Icon(
                            Icons.local_fire_department,
                            size: 12, // Reduced from 14 to 12
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 1), // Reduced from 2 to 1
                          Text(
                            '${habit.currentStreak}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Quick action button
              SizedBox(
                width: 32, // Constrain button width
                height: 32, // Constrain button height
                child: IconButton(
                  padding: EdgeInsets.zero, // Remove default padding
                  onPressed: () {
                    HapticService.buttonTap();
                    onToggleCompletion?.call();
                  },
                  icon: Icon(
                    isCompleted ? Icons.undo : Icons.check,
                    color: habitColor,
                    size: 18, // Smaller icon
                  ),
                  tooltip: isCompleted ? 'Mark incomplete' : 'Mark complete',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
