import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habits_bloc.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/services/haptic_service.dart';
import 'add_edit_habit_page.dart';

enum CalendarFilter {
  lastWeek,
  lastMonth,
  last3Months,
  last6Months,
  thisYear,
  allTime,
}

extension CalendarFilterExtension on CalendarFilter {
  String get label {
    switch (this) {
      case CalendarFilter.lastWeek:
        return '7 Days';
      case CalendarFilter.lastMonth:
        return '30 Days';
      case CalendarFilter.last3Months:
        return '3 Months';
      case CalendarFilter.last6Months:
        return '6 Months';
      case CalendarFilter.thisYear:
        return 'This Year';
      case CalendarFilter.allTime:
        return 'All Time';
    }
  }

  DateTime getStartDate(DateTime now) {
    switch (this) {
      case CalendarFilter.lastWeek:
        return now.subtract(const Duration(days: 6));
      case CalendarFilter.lastMonth:
        return now.subtract(const Duration(days: 29));
      case CalendarFilter.last3Months:
        return now.subtract(const Duration(days: 89));
      case CalendarFilter.last6Months:
        return now.subtract(const Duration(days: 179));
      case CalendarFilter.thisYear:
        return DateTime(now.year, 1, 1);
      case CalendarFilter.allTime:
        return DateTime(2020, 1, 1); // Arbitrary start date
    }
  }
}

class HabitDetailPage extends StatefulWidget {
  final Habit habit;

  const HabitDetailPage({
    super.key,
    required this.habit,
  });

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  CalendarFilter _selectedFilter = CalendarFilter.lastMonth;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitsBloc, HabitsState>(
      builder: (context, state) {
        // Get the most current habit data from the state
        Habit currentHabit = widget.habit;
        if (state is HabitsLoaded) {
          final updatedHabit = state.habits.firstWhere(
            (h) => h.id == widget.habit.id,
            orElse: () => widget.habit,
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
              final habitExists =
                  state.habits.any((h) => h.id == widget.habit.id);
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = _selectedFilter.getStartDate(today);

    // Filter completed dates based on selected period
    final filteredDates = currentHabit.completedDates.where((date) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      return (dateOnly.isAtSameMomentAs(startDate) ||
              dateOnly.isAfter(startDate)) &&
          (dateOnly.isBefore(today) || dateOnly.isAtSameMomentAs(today));
    }).toList();

    // Count completions in filtered period
    final completionsInPeriod = filteredDates.length;

    // Get habit color
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

    // Convert completed dates to Map for heatmap
    final Map<DateTime, int> datasets = {};
    for (final date in currentHabit.completedDates) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      if ((dateOnly.isAtSameMomentAs(startDate) ||
              dateOnly.isAfter(startDate)) &&
          (dateOnly.isBefore(today) || dateOnly.isAtSameMomentAs(today))) {
        datasets[dateOnly] = 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            // Filter dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButton<CalendarFilter>(
                value: _selectedFilter,
                underline: const SizedBox(),
                isDense: true,
                items: CalendarFilter.values.map((filter) {
                  return DropdownMenuItem(
                    value: filter,
                    child: Text(
                      filter.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  );
                }).toList(),
                onChanged: (CalendarFilter? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFilter = newValue;
                    });
                    HapticService.selectionClick();
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // GitHub-style heatmap calendar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HeatMap(
              startDate: startDate,
              endDate: today,
              datasets: datasets,
              colorMode: ColorMode.opacity,
              defaultColor: Theme.of(context).colorScheme.surfaceContainer,
              textColor: Theme.of(context).colorScheme.onSurfaceVariant,
              showColorTip: false,
              showText: false,
              scrollable: false,
              size: 24,
              margin: const EdgeInsets.all(2),
              borderRadius: 4,
              colorsets: {
                1: habitColor,
              },
              onClick: (value) {
                // Show date on tap
                final dateStr = '${value.day}/${value.month}/${value.year}';
                final isCompleted = datasets
                    .containsKey(DateTime(value.year, value.month, value.day));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isCompleted
                        ? '✅ Completed on $dateStr'
                        : '⭕ Not done on $dateStr'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Summary stats
        Row(
          children: [
            Expanded(
              child: _buildSmallStatCard(
                context,
                'Completions',
                '$completionsInPeriod',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallStatCard(
                context,
                'Current Streak',
                '${currentHabit.currentStreak}',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallStatCard(
                context,
                'Best Streak',
                '${currentHabit.longestStreak}',
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
