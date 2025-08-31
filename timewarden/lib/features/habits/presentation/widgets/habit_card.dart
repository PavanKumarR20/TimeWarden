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
          padding: const EdgeInsets.all(12),
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
                      width: 40,
                      height: 40,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isCurrentlyCompleted
                              ? Container(
                                  key: ValueKey('completed'),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                )
                              : Container(
                                  key: ValueKey('incomplete'),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),

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
                      const SizedBox(height: 2),
                      Text(
                        habit.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
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
                onPressed: () {
                  HapticService.buttonTap();
                  onToggleCompletion?.call();
                },
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
