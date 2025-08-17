import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habits_bloc.dart';
import '../../../../core/widgets/animations.dart';

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
    final isCompleted = habit.isCompletedToday;
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
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                    return prevHabit.isCompletedToday !=
                        currHabit.isCompletedToday;
                  }
                  return false;
                },
                builder: (context, state) {
                  final currentHabit = state is HabitsLoaded
                      ? state.habits.firstWhere((h) => h.id == habit.id,
                          orElse: () => habit)
                      : habit;
                  final isCurrentlyCompleted = currentHabit.isCompletedToday;

                  return AnimatedScaleButton(
                    onTap: onToggleCompletion,
                    child: Container(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isCurrentlyCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  key: ValueKey('completed'),
                                  color: Colors.green.shade600,
                                  size: 32,
                                  weight: 800,
                                )
                              : Icon(
                                  Icons.close_rounded,
                                  key: ValueKey('incomplete'),
                                  color: Colors.grey.shade600,
                                  size: 32,
                                  weight: 800,
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),

              // Habit details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : null,
                          ),
                    ),
                    if (habit.description != null &&
                        habit.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
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
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 2),
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
              IconButton(
                onPressed: onToggleCompletion,
                icon: Icon(
                  isCompleted ? Icons.undo : Icons.check,
                  color: habitColor,
                ),
                tooltip: isCompleted ? 'Mark incomplete' : 'Mark complete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
