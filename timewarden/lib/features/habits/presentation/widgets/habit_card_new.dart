import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habits_bloc.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/completion_celebration.dart';

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

                  return CompletionCelebration(
                    isCompleted: isCurrentlyCompleted,
                    color: habitColor,
                    child: AnimatedScaleButton(
                      onTap: onToggleCompletion,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: isCurrentlyCompleted
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    habitColor,
                                    habitColor.withOpacity(0.8),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    habitColor.withOpacity(0.1),
                                    habitColor.withOpacity(0.05),
                                  ],
                                ),
                          boxShadow: isCurrentlyCompleted
                              ? [
                                  BoxShadow(
                                    color: habitColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .shadow
                                        .withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isCurrentlyCompleted
                                ? Container(
                                    key: ValueKey('completed'),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 28,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.15),
                                          offset: const Offset(0, 1),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    key: ValueKey('incomplete'),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: habitColor.withOpacity(0.2),
                                            border: Border.all(
                                              color:
                                                  habitColor.withOpacity(0.4),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.add_rounded,
                                          color: habitColor,
                                          size: 20,
                                        ),
                                        if (habit.icon != null &&
                                            habit.icon!.isNotEmpty)
                                          Positioned(
                                            top: -2,
                                            right: -2,
                                            child: Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline
                                                      .withOpacity(0.2),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  habit.icon!,
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
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
