import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/habits_bloc.dart';
import '../../services/habit_streak_service.dart';
import '../../domain/entities/habit.dart';

class HabitStreaksWidget extends StatelessWidget {
  const HabitStreaksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitsBloc, HabitsState>(
      builder: (context, state) {
        if (state is HabitsLoaded) {
          final activeHabits = state.habits.where((h) => h.isActive).toList();
          
          if (activeHabits.isEmpty) {
            return const _EmptyStreaksCard();
          }

          // Sort habits by current streak (highest first)
          activeHabits.sort((a, b) {
            final streakA = HabitStreakService.calculateCurrentStreak(a);
            final streakB = HabitStreakService.calculateCurrentStreak(b);
            return streakB.compareTo(streakA);
          });

          return _StreaksCard(habits: activeHabits.take(5).toList());
        }

        return const _LoadingStreaksCard();
      },
    );
  }
}

class _StreaksCard extends StatelessWidget {
  final List<Habit> habits;

  const _StreaksCard({required this.habits});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 3,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.8),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.1),
                        theme.colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habit Streaks',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Keep the momentum going!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.1),
                        theme.colorScheme.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Top ${habits.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...habits.map((habit) => _StreakItem(habit: habit)),
          ],
        ),
      ),
    );
  }
}

class _StreakItem extends StatelessWidget {
  final Habit habit;

  const _StreakItem({required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streak = HabitStreakService.calculateCurrentStreak(habit);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Habit Icon/Color
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getHabitColor(habit, theme),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                habit.icon ?? _getCategoryEmoji(habit.category),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Habit Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  habit.frequency.displayText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Streak Display
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: streak > 0 ? Colors.orange : theme.colorScheme.outline,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    streak.toString(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: streak > 0 ? Colors.orange : theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _getStreakPeriod(habit),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getHabitColor(Habit habit, ThemeData theme) {
    if (habit.color != null) {
      try {
        return Color(int.parse(habit.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fallback to category color
      }
    }
    
    // Default category colors
    switch (habit.category) {
      case HabitCategory.health:
        return Colors.green.withOpacity(0.2);
      case HabitCategory.fitness:
        return Colors.red.withOpacity(0.2);
      case HabitCategory.learning:
        return Colors.blue.withOpacity(0.2);
      case HabitCategory.productivity:
        return Colors.purple.withOpacity(0.2);
      case HabitCategory.mindfulness:
        return Colors.indigo.withOpacity(0.2);
      case HabitCategory.social:
        return Colors.pink.withOpacity(0.2);
      case HabitCategory.creative:
        return Colors.orange.withOpacity(0.2);
      case HabitCategory.other:
        return theme.colorScheme.primaryContainer;
    }
  }

  String _getCategoryEmoji(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return '🏥';
      case HabitCategory.fitness:
        return '💪';
      case HabitCategory.learning:
        return '📚';
      case HabitCategory.productivity:
        return '⚡';
      case HabitCategory.mindfulness:
        return '🧘';
      case HabitCategory.social:
        return '👥';
      case HabitCategory.creative:
        return '🎨';
      case HabitCategory.other:
        return '📋';
    }
  }

  String _getStreakPeriod(Habit habit) {
    switch (habit.frequency.type) {
      case HabitFrequencyType.daily:
        return 'days';
      case HabitFrequencyType.everyNDays:
        return 'cycles';
      case HabitFrequencyType.timesPerWeek:
        return 'weeks';
      case HabitFrequencyType.timesPerMonth:
        return 'months';
      case HabitFrequencyType.timesInPeriod:
        return 'periods';
    }
  }
}

class _EmptyStreaksCard extends StatelessWidget {
  const _EmptyStreaksCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceContainerHighest,
              theme.colorScheme.surfaceContainer,
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Start Building Streaks!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first habit to begin tracking streaks',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingStreaksCard extends StatelessWidget {
  const _LoadingStreaksCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainer,
        ),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Streaks...',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
