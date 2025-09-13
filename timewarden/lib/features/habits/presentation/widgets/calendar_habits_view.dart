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
    // Reverse the order so latest days are on the left
    final days =
        List.generate(4, (index) => today.subtract(Duration(days: index)));

    return Column(
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
              return _buildHabitRow(context, habit, days);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDaysHeader(List<DateTime> days) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8), // Reduced padding
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
            // Habit name column space - increased for more text space
            const SizedBox(width: 180), // Increased from 140 to 180
            // Days columns
            ...days.map((day) {
              final isToday = _isToday(day);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal:
                          1), // Reduced from 2 to match checkbox spacing
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(day).toUpperCase(),
                        style: TextStyle(
                          fontSize: 8, // Reduced from 9
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2), // Reduced from 3
                      Container(
                        width: 28, // Reduced from 32
                        height: 20, // Reduced from 24
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(10), // Reduced from 12
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
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10), // Reduced padding
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: habitColor,
            width: 3, // Reduced from 4
          ),
        ),
      ),
      child: Row(
        children: [
          // Habit info - increased width for more text space
          SizedBox(
            width: 180, // Increased from 140 to 180
            child: Padding(
              padding: const EdgeInsets.only(left: 8), // Reduced from 12
              child: GestureDetector(
                onTap: () => _navigateToHabitDetail(context, habit),
                child: Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 14, // Reduced from 16
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.1, // Reduced from 1.2
                  ),
                  maxLines: 1, // Changed from 2 to 1 to prevent wrapping
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Completion checkboxes for each day
          ...days.map((day) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 1), // Reduced from 2 to 1 for tighter spacing
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

            // Check if the habit's period completion status changed
            // This affects all days in the period, not just the specific date
            final prevPeriodCompleted =
                prevHabit.isCompletedForPeriodButNotToday;
            final currPeriodCompleted =
                currHabit.isCompletedForPeriodButNotToday;

            return prevCompleted != currCompleted ||
                prevPeriodCompleted != currPeriodCompleted;
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
          final isCompletedForPeriodOnly =
              currentHabit.isCompletedForPeriodButNotToday && !isCompleted;

          return AnimatedScaleButton(
            onTap: () => _toggleCompletion(context, currentHabit, day),
            child: Container(
              width: 32, // Reduced from 36
              height: 32, // Reduced from 36
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(
                      milliseconds:
                          400), // Increased from 300 for more noticeable animation
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.8, // Start smaller for bounce effect
                        end: 1.2, // Scale up beyond normal size
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
                  child: isCompleted
                      ? Container(
                          key: const ValueKey('completed_today'),
                          width: 24, // Reduced from 28
                          height: 24, // Reduced from 28
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? [
                                      const Color(
                                          0xFF059669), // Darker green for dark mode
                                      const Color(0xFF047857),
                                    ]
                                  : [
                                      const Color(
                                          0xFF10B981), // Brighter green for light mode
                                      const Color(0xFF059669),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(12), // Reduced from 14
                            boxShadow:
                                Theme.of(context).brightness == Brightness.dark
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF059669)
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFF10B981)
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16, // Reduced from 18
                          ),
                        )
                      : isCompletedForPeriodOnly
                          ? Container(
                              key: const ValueKey('completed_period'),
                              width: 24, // Reduced from 28
                              height: 24, // Reduced from 28
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? [
                                          const Color(
                                              0xFF7C3AED), // Purple for dark mode
                                          const Color(0xFF6D28D9),
                                        ]
                                      : [
                                          const Color(
                                              0xFF8B5CF6), // Purple for light mode
                                          const Color(0xFF7C3AED),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                    12), // Reduced from 14
                                boxShadow: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF7C3AED)
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFF8B5CF6)
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 16, // Reduced from 18
                              ),
                            )
                          : Container(
                              key: const ValueKey('incomplete'),
                              width: 20, // Reduced from 24
                              height: 20, // Reduced from 24
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(
                                        0xFF1F2937) // Dark background for dark mode
                                    : const Color(
                                        0xFFF9FAFB), // Light background for light mode
                                borderRadius: BorderRadius.circular(
                                    10), // Reduced from 12
                                border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(
                                          0xFF4B5563) // Better contrast for dark mode
                                      : const Color(
                                          0xFFD1D5DB), // Light gray for light mode
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.radio_button_unchecked,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(
                                        0xFF6B7280) // Better visibility in dark mode
                                    : const Color(
                                        0xFF9CA3AF), // Standard gray for light mode
                                size: 14, // Reduced from 16
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

    // Show brief success animation for completion
    if (!isCompleted) {
      _showCompletionSuccessAnimation(context);
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

  void _showCompletionSuccessAnimation(BuildContext context) {
    // Show a brief overlay animation for successful completion - slides up from bottom
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1.0), // Start from bottom
              end: const Offset(0, -0.3), // Slide up to 70% from bottom
            ).animate(CurvedAnimation(
              parent: AnimationController(
                duration: const Duration(milliseconds: 800),
                vsync: Navigator.of(context),
              )..forward(),
              curve: Curves.elasticOut,
            )),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: AnimationController(
                  duration: const Duration(milliseconds: 600),
                  vsync: Navigator.of(context),
                )..forward(),
                curve: Curves.easeOut,
              )),
              child: Container(
                margin: const EdgeInsets.all(20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF059669).withOpacity(0.95)
                      : const Color(0xFF10B981).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF059669).withOpacity(0.5)
                          : const Color(0xFF10B981).withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Great job! 🎉',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

    Overlay.of(context).insert(overlayEntry);

    // Remove the overlay after animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      overlayEntry?.remove();
    });
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }
}
