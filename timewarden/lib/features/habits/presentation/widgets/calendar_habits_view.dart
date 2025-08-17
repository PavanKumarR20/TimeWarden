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
        List.generate(7, (index) => today.subtract(Duration(days: 6 - index)));

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: Column(
                  children: [
                    Text(
                      DateFormat('E').format(day).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Habit info
          SizedBox(
            width: 140,
            child: Row(
              children: [
                // Colored indicator
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: habitColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Habit name
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToHabitDetail(context, habit),
                    child: Text(
                      habit.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Completion checkboxes for each day
          ...days.map((day) => Expanded(
                child:
                    _buildCompletionCheckbox(context, habit, day, habitColor),
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
              width: 32,
              height: 32,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          key: const ValueKey('check'),
                          color: Colors.green.shade600,
                          size: 24,
                          weight: 800,
                        )
                      : Icon(
                          Icons.close_rounded,
                          key: const ValueKey('close'),
                          color: Colors.grey.shade600,
                          size: 24,
                          weight: 800,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isHabitCompletedOnDay(Habit habit, DateTime day) {
    final dayString = DateFormat('yyyy-MM-dd').format(day);
    return habit.completedDates.any((date) {
      return DateFormat('yyyy-MM-dd').format(date) == dayString;
    });
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
