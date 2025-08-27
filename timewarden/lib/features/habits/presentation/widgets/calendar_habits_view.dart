import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habits_bloc.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/services/haptic_service.dart';
import '../pages/habit_detail_page.dart';

class CalendarHabitsView extends StatelessWidget {
  final List<Habit> habits;

  const CalendarHabitsView({
    super.key,
    required this.habits,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days =
        List.generate(5, (index) => today.subtract(Duration(days: 4 - index)));

    return SlideInAnimation(
      child: Column(
        children: [
          // Header with days
          _buildDaysHeader(days),
          const Divider(height: 1),

          // Habits list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: habits.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final habit = habits[index];
                return FadeInAnimation(
                  delay: Duration(milliseconds: index * 100),
                  child: _buildHabitRow(context, habit, days),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysHeader(List<DateTime> days) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.3),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            // Habit name column space
            const SizedBox(width: 140),
            // Days columns
            ...days.map((day) {
              final isToday = _isToday(day);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(day).toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 32,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: isToday
                              ? null
                              : Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                        ),
                        child: Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isToday
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitRow(
      BuildContext context, Habit habit, List<DateTime> days) {
    Color habitColor;
    try {
      habitColor = habit.color != null
          ? Color(int.parse(habit.color!.replaceAll('#', '').padLeft(8, 'FF'),
              radix: 16))
          : Theme.of(context).colorScheme.primary;
    } catch (e) {
      habitColor = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: habitColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          // Habit info
          SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () => _navigateToHabitDetail(context, habit),
                child: Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Completion checkboxes for each day
          ...days.map((day) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child:
                      _buildCompletionCheckbox(context, habit, day, habitColor),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCompletionCheckbox(
      BuildContext context, Habit habit, DateTime day, Color habitColor) {
    final dateOnly = DateTime(day.year, day.month, day.day);

    // Don't show checkbox for future dates
    if (day.isAfter(DateTime.now())) {
      return const SizedBox();
    }

    // Don't show checkbox if habit shouldn't appear on this day based on frequency
    if (!_shouldShowHabitOnDay(habit, day)) {
      return const SizedBox();
    }

    return Center(
      child: BlocBuilder<HabitsBloc, HabitsState>(
        buildWhen: (previous, current) {
          // Only rebuild this specific checkbox if this specific habit changed
          if (previous is HabitsLoaded && current is HabitsLoaded) {
            final prevHabit = previous.habits.firstWhere(
              (h) => h.id == habit.id,
              orElse: () => habit,
            );
            final currHabit = current.habits.firstWhere(
              (h) => h.id == habit.id,
              orElse: () => habit,
            );

            // Check if completion status changed for this specific date
            final prevCompleted = prevHabit.completedDates.any((date) =>
                date.year == dateOnly.year &&
                date.month == dateOnly.month &&
                date.day == dateOnly.day);
            final currCompleted = currHabit.completedDates.any((date) =>
                date.year == dateOnly.year &&
                date.month == dateOnly.month &&
                date.day == dateOnly.day);

            return prevCompleted != currCompleted;
          }
          return false;
        },
        builder: (context, state) {
          if (state is! HabitsLoaded) return const SizedBox();

          final currentHabit = state.habits.firstWhere(
            (h) => h.id == habit.id,
            orElse: () => habit,
          );

          final isCompleted = currentHabit.completedDates.any((date) =>
              date.year == dateOnly.year &&
              date.month == dateOnly.month &&
              date.day == dateOnly.day);

          return AnimatedScaleButton(
            onTap: () => _toggleCompletion(context, currentHabit, day),
            child: Container(
              width: 36,
              height: 36,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: RotationTransition(
                        turns: animation,
                        child: child,
                      ),
                    );
                  },
                  child: isCompleted
                      ? Container(
                          key: const ValueKey('completed'),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade200,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                        )
                      : Container(
                          key: const ValueKey('incomplete'),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.radio_button_unchecked,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _shouldShowHabitOnDay(Habit habit, DateTime day) {
    // For now, show all habits on all days
    // This can be enhanced based on frequency settings
    final createdDate = habit.createdAt;
    return day.isAfter(createdDate.subtract(const Duration(days: 1))) ||
        day.isAtSameMomentAs(createdDate);
  }

  void _toggleCompletion(BuildContext context, Habit habit, DateTime day) {
    final currentHabit = context.read<HabitsBloc>().state is HabitsLoaded
        ? (context.read<HabitsBloc>().state as HabitsLoaded)
            .habits
            .firstWhere((h) => h.id == habit.id, orElse: () => habit)
        : habit;

    final dateOnly = DateTime(day.year, day.month, day.day);
    final isCompleted = currentHabit.completedDates.any((date) =>
        date.year == dateOnly.year &&
        date.month == dateOnly.month &&
        date.day == dateOnly.day);

    // Provide haptic feedback based on action
    if (isCompleted) {
      HapticService.habitUncompleted(); // Light haptic for unchecking
    } else {
      HapticService.habitCompleted(); // Medium haptic for checking
    }

    context.read<HabitsBloc>().add(
          HabitCompletionToggled(
            habitId: habit.id,
            date: day,
          ),
        );
  }

  void _navigateToHabitDetail(BuildContext context, Habit habit) {
    // Haptic feedback for navigation
    HapticService.buttonTap();

    // Get the BLoC reference before navigating
    final habitsBloc = context.read<HabitsBloc>();

    Navigator.of(context).push(
      CustomPageRoute(
        child: BlocProvider.value(
          value: habitsBloc,
          child: HabitDetailPage(habit: habit),
        ),
      ),
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }
}
