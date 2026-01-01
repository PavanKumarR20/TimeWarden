import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habits_bloc.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/widgets/completion_success_animation.dart';

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
    final isCompleted = habit.frequency.type == HabitFrequencyType.daily
        ? habit.isCompletedForCurrentPeriod
        : (habit.isCompletedToday || habit.isCompletedForCurrentPeriod);

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

                    // Check if completion status changed for this habit
                    final prevCompleted =
                        prevHabit.frequency.type == HabitFrequencyType.daily
                            ? prevHabit.isCompletedForCurrentPeriod
                            : (prevHabit.isCompletedToday ||
                                prevHabit.isCompletedForCurrentPeriod);
                    final currCompleted =
                        currHabit.frequency.type == HabitFrequencyType.daily
                            ? currHabit.isCompletedForCurrentPeriod
                            : (currHabit.isCompletedToday ||
                                currHabit.isCompletedForCurrentPeriod);

                    // Also check if the period completion state changed
                    final prevPeriodOnly =
                        prevHabit.isCompletedForPeriodButNotToday;
                    final currPeriodOnly =
                        currHabit.isCompletedForPeriodButNotToday;

                    return prevCompleted != currCompleted ||
                        prevPeriodOnly != currPeriodOnly;
                  }
                  return false;
                },
                builder: (context, state) {
                  final currentHabit = state is HabitsLoaded
                      ? state.habits.firstWhere((h) => h.id == habit.id,
                          orElse: () => habit)
                      : habit;
                  final isCurrentlyCompleted =
                      currentHabit.frequency.type == HabitFrequencyType.daily
                          ? currentHabit.isCompletedForCurrentPeriod
                          : (currentHabit.isCompletedToday ||
                              currentHabit.isCompletedForCurrentPeriod);
                  final isCompletedForPeriodOnly =
                      currentHabit.isCompletedForPeriodButNotToday;

                  return AnimatedScaleButton(
                    onTap: () {
                      HapticService.buttonTap();
                      // Show success animation for completion
                      if (!isCurrentlyCompleted) {
                        _showCompletionSuccessAnimation(context);
                      }
                      onToggleCompletion?.call();
                    },
                    child: SizedBox(
                      width:
                          28, // Further reduced from 32 to 28 for more text space
                      height:
                          28, // Further reduced from 32 to 28 for more text space
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(
                              milliseconds:
                                  400), // Increased from 200 for more noticeable animation
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.7, // Start smaller for bounce effect
                                end: 1.3, // Scale up beyond normal size
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves
                                    .elasticOut, // Changed to elastic for bounce effect
                              )),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: isCurrentlyCompleted
                              ? Container(
                                  key: ValueKey('completed_today'),
                                  width: 20, // Reduced from 24 to 20
                                  height: 20, // Reduced from 24 to 20
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(
                                            0xFF059669) // Darker green for dark mode
                                        : const Color(
                                            0xFF10B981), // Brighter green for light mode
                                    borderRadius: BorderRadius.circular(
                                        10), // Reduced from 12 to 10
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 14, // Reduced from 16 to 14
                                  ),
                                )
                              : isCompletedForPeriodOnly
                                  ? Container(
                                      key: ValueKey('completed_period'),
                                      width: 20, // Reduced from 24 to 20
                                      height: 20, // Reduced from 24 to 20
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(
                                                0xFF7C3AED) // Purple for dark mode
                                            : const Color(
                                                0xFF8B5CF6), // Purple for light mode
                                        borderRadius: BorderRadius.circular(
                                            10), // Reduced from 12 to 10
                                      ),
                                      child: Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 14, // Reduced from 16 to 14
                                      ),
                                    )
                                  : Container(
                                      key: ValueKey('incomplete'),
                                      width: 20, // Reduced from 24 to 20
                                      height: 20, // Reduced from 24 to 20
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
                                            10), // Reduced from 12 to 10
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
                    // Description removed
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
              AnimatedScaleButton(
                onTap: () {
                  HapticService.buttonTap();
                  // Show success animation for completion
                  if (!isCompleted) {
                    _showCompletionSuccessAnimation(context);
                  }
                  onToggleCompletion?.call();
                },
                child: Container(
                  width: 28, // Reduced from 32 to 28 to match completion button
                  height:
                      28, // Reduced from 32 to 28 to match completion button
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.3)
                        : habitColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : habitColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isCompleted ? Icons.undo : Icons.check,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : habitColor,
                    size: 16, // Reduced from 18 to 16
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionSuccessAnimation(BuildContext context) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          CompletionSuccessAnimation(
            pointsValue: habit.pointsValue,
            onComplete: () => overlayEntry?.remove(),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }
}
