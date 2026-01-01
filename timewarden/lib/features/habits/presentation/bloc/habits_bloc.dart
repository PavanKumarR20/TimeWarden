import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/points_service.dart';
import '../../../dashboard/data/repositories/user_stats_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class HabitsEvent extends Equatable {
  const HabitsEvent();

  @override
  List<Object?> get props => [];
}

class HabitsLoadRequested extends HabitsEvent {}

class HabitAdded extends HabitsEvent {
  final Habit habit;

  const HabitAdded(this.habit);

  @override
  List<Object> get props => [habit];
}

class HabitUpdated extends HabitsEvent {
  final Habit habit;

  const HabitUpdated(this.habit);

  @override
  List<Object> get props => [habit];
}

class HabitDeleted extends HabitsEvent {
  final String habitId;

  const HabitDeleted(this.habitId);

  @override
  List<Object> get props => [habitId];
}

class HabitCompletionToggled extends HabitsEvent {
  final String habitId;
  final DateTime date;

  const HabitCompletionToggled({
    required this.habitId,
    required this.date,
  });

  @override
  List<Object> get props => [habitId, date];
}

class PointsManuallyAdjusted extends HabitsEvent {
  final double delta;

  const PointsManuallyAdjusted(this.delta);

  @override
  List<Object> get props => [delta];
}

class PointRewardDescriptionUpdated extends HabitsEvent {
  final String description;

  const PointRewardDescriptionUpdated(this.description);

  @override
  List<Object> get props => [description];
}

// States
abstract class HabitsState extends Equatable {
  const HabitsState();

  @override
  List<Object?> get props => [];
}

class HabitsInitial extends HabitsState {}

class HabitsLoading extends HabitsState {}

class HabitsLoaded extends HabitsState {
  final List<Habit> habits;

  const HabitsLoaded(this.habits);

  @override
  List<Object> get props => [habits];
}

class HabitsError extends HabitsState {
  final String message;

  const HabitsError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC - Much simpler with Future-based approach
class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  final HabitRepository _habitRepository;
  late final UserStatsRepositoryImpl _statsRepository;

  HabitsBloc(this._habitRepository) : super(HabitsInitial()) {
    _statsRepository = UserStatsRepositoryImpl(FirebaseService());
    on<HabitsLoadRequested>(_onHabitsLoadRequested);
    on<HabitAdded>(_onHabitAdded);
    on<HabitUpdated>(_onHabitUpdated);
    on<HabitDeleted>(_onHabitDeleted);
    on<HabitCompletionToggled>(_onHabitCompletionToggled);
    on<PointsManuallyAdjusted>(_onPointsManuallyAdjusted);
    on<PointRewardDescriptionUpdated>(_onPointRewardDescriptionUpdated);
  }

  Future<void> _onHabitsLoadRequested(
    HabitsLoadRequested event,
    Emitter<HabitsState> emit,
  ) async {
    LogService.debug('Load requested', tag: 'HabitsBloc');
    emit(HabitsLoading());

    try {
      final habits = await _habitRepository.getHabits();
      LogService.debug('Loaded ${habits.length} habits successfully',
          tag: 'HabitsBloc');

      // Check and reset daily points if needed
      await _checkAndResetDailyPoints();

      emit(HabitsLoaded(habits));
    } catch (e) {
      LogService.error('Error loading habits', tag: 'HabitsBloc', error: e);
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> _onHabitAdded(
    HabitAdded event,
    Emitter<HabitsState> emit,
  ) async {
    try {
      LogService.debug('Adding habit: ${event.habit.name}', tag: 'HabitsBloc');
      await _habitRepository.addHabit(event.habit);
      LogService.debug('Habit added successfully, refreshing list',
          tag: 'HabitsBloc');
      // Refresh the list after adding
      add(HabitsLoadRequested());
    } catch (e) {
      LogService.error('Error adding habit', tag: 'HabitsBloc', error: e);
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> _onHabitUpdated(
    HabitUpdated event,
    Emitter<HabitsState> emit,
  ) async {
    try {
      LogService.debug('Updating habit: ${event.habit.name}',
          tag: 'HabitsBloc');
      await _habitRepository.updateHabit(event.habit);
      LogService.debug('Habit updated successfully, refreshing list',
          tag: 'HabitsBloc');
      // Refresh the list after updating
      add(HabitsLoadRequested());
    } catch (e) {
      LogService.error('Error updating habit', tag: 'HabitsBloc', error: e);
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> _onHabitDeleted(
    HabitDeleted event,
    Emitter<HabitsState> emit,
  ) async {
    try {
      LogService.debug('Deleting habit: ${event.habitId}', tag: 'HabitsBloc');
      await _habitRepository.deleteHabit(event.habitId);
      LogService.debug('Habit deleted successfully, refreshing list',
          tag: 'HabitsBloc');
      // Refresh the list after deleting
      add(HabitsLoadRequested());
    } catch (e) {
      LogService.error('Error deleting habit', tag: 'HabitsBloc', error: e);
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> _onHabitCompletionToggled(
    HabitCompletionToggled event,
    Emitter<HabitsState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is HabitsLoaded) {
        final habitIndex = currentState.habits.indexWhere(
          (h) => h.id == event.habitId,
        );

        if (habitIndex == -1) return;

        final habit = currentState.habits[habitIndex];
        final dateOnly =
            DateTime(event.date.year, event.date.month, event.date.day);
        final isCompleted = habit.completedDates.any((date) =>
            date.year == dateOnly.year &&
            date.month == dateOnly.month &&
            date.day == dateOnly.day);

        print('🎯 HABIT COMPLETION TOGGLED:');
        print('   - Habit: ${habit.name}');
        print('   - Date: ${dateOnly.toString().split(' ')[0]}');
        print('   - Currently completed: $isCompleted');

        LogService.debug(
            'Toggling completion for habit ${habit.name}, currently completed: $isCompleted',
            tag: 'HabitsBloc');

        // Update the habit locally first for immediate UI feedback
        List<DateTime> updatedCompletedDates;
        if (isCompleted) {
          updatedCompletedDates = habit.completedDates
              .where((date) => !(date.year == dateOnly.year &&
                  date.month == dateOnly.month &&
                  date.day == dateOnly.day))
              .toList();
        } else {
          updatedCompletedDates = [...habit.completedDates, dateOnly];
        }

        final updatedHabit =
            habit.copyWith(completedDates: updatedCompletedDates);
        final updatedHabits = List<Habit>.from(currentState.habits);
        updatedHabits[habitIndex] = updatedHabit;

        print('   - Now completed: ${!isCompleted}');
        print('🔄 Habit updated locally, emitting new state...');

        // Emit the updated state immediately for instant UI feedback
        emit(HabitsLoaded(updatedHabits));

        // Then update the backend asynchronously
        if (isCompleted) {
          await _habitRepository.markHabitIncomplete(event.habitId, event.date);
          // Deduct points when uncompleting
          await _deductPointsForHabit(habit);
        } else {
          await _habitRepository.markHabitComplete(event.habitId, event.date);
          // Award points when completing
          await _awardPointsForHabit(habit);
        }

        LogService.debug('Habit completion toggled successfully in backend',
            tag: 'HabitsBloc');

        print(
            '🔍 Backend updated successfully, now checking for perfect day...');

        // Check for perfect day completion after habit is updated
        _checkPerfectDayCompletion(updatedHabits, event.date);
      }
    } catch (e) {
      LogService.error('Error toggling habit completion',
          tag: 'HabitsBloc', error: e);
      // Reload the data to sync with backend if there's an error
      add(HabitsLoadRequested());
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> _checkPerfectDayCompletion(
      List<Habit> habits, DateTime date) async {
    try {
      final userId = FirebaseService().currentUserId;
      print('🔍 PERFECT DAY CHECK STARTED - User ID: $userId');

      if (userId == null) {
        print('❌ No user ID, skipping perfect day check');
        return;
      }

      // Only check for today's perfect days
      final today = DateTime.now();
      final dateOnly = DateTime(date.year, date.month, date.day);
      final todayOnly = DateTime(today.year, today.month, today.day);

      print(
          '🗓️ Checking date: ${dateOnly.toString().split(' ')[0]} vs today: ${todayOnly.toString().split(' ')[0]}');

      if (dateOnly.millisecondsSinceEpoch != todayOnly.millisecondsSinceEpoch) {
        print('❌ Date is not today, skipping perfect day check');
        return; // Only track perfect days for today
      }

      print('📋 Total habits to analyze: ${habits.length}');

      // Get habits that should be done today
      final activeHabitsForToday = <Habit>[];

      for (final habit in habits) {
        print('🔎 Analyzing habit: ${habit.name}');
        print('   - Frequency type: ${habit.frequency.type}');
        print(
            '   - Is completed for current period: ${habit.isCompletedForCurrentPeriod}');
        print('   - Is completed today: ${habit.isCompletedToday}');

        bool shouldInclude = false;

        // Always include daily habits
        if (habit.frequency.type == HabitFrequencyType.daily) {
          shouldInclude = true;
          print('   ✅ Including (daily habit)');
        } else {
          // For other frequencies, include if not completed for period
          if (!habit.isCompletedForCurrentPeriod) {
            shouldInclude = true;
            print('   ✅ Including (not completed for current period)');
          } else {
            print('   ❌ Excluding (already completed for current period)');
          }
        }

        if (shouldInclude) {
          activeHabitsForToday.add(habit);
        }
      }

      print('📊 Active habits for today: ${activeHabitsForToday.length}');
      for (final habit in activeHabitsForToday) {
        print(
            '   - ${habit.name} (completed today: ${habit.isCompletedToday})');
      }

      if (activeHabitsForToday.isEmpty) {
        print('❌ No active habits for today, skipping perfect day check');
        return;
      }

      // Check if ALL active habits for today are completed
      final completedHabitsToday = activeHabitsForToday.where((habit) {
        return habit.isCompletedToday;
      }).toList();

      final isNowPerfectDay =
          completedHabitsToday.length == activeHabitsForToday.length;

      print('📈 PERFECT DAY ANALYSIS:');
      print('   - Active habits for today: ${activeHabitsForToday.length}');
      print('   - Completed today: ${completedHabitsToday.length}');
      print('   - Is perfect day: $isNowPerfectDay');

      if (isNowPerfectDay) {
        // Check if we already incremented for today
        final alreadyIncremented = await _wasAlreadyIncrementedToday(userId);
        print('   - Already incremented today: $alreadyIncremented');

        if (!alreadyIncremented) {
          print('🚀 INCREMENTING PERFECT DAYS COUNTER...');
          await _statsRepository.incrementPerfectDays(userId);
          await _markTodayAsIncremented(userId);

          print(
              '🔥🔥🔥 PERFECT DAY ACHIEVED! Perfect days incremented! 🔥🔥🔥');
          print(
              '🎉 CONGRATULATIONS! Perfect day completed! All habits done for today!');

          // Could add a notification or UI feedback here in the future
        } else {
          print('ℹ️ Perfect day already counted for today');
        }
      } else {
        print(
            '❌ Not a perfect day yet - ${completedHabitsToday.length}/${activeHabitsForToday.length} habits completed');
      }
    } catch (e) {
      print('💥 ERROR in perfect day check: $e');
      LogService.error('Error checking perfect day completion',
          error: e, tag: 'HabitsBloc');
    }
  }

  Future<bool> _wasAlreadyIncrementedToday(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final key =
          'perfect_day_incremented_${userId}_${today.year}_${today.month}_${today.day}';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _markTodayAsIncremented(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final key =
          'perfect_day_incremented_${userId}_${today.year}_${today.month}_${today.day}';
      await prefs.setBool(key, true);
    } catch (e) {
      LogService.error('Error marking today as incremented',
          error: e, tag: 'HabitsBloc');
    }
  }

  Future<void> _checkAndResetDailyPoints() async {
    try {
      final userId = FirebaseService().currentUserId;
      if (userId == null) return;

      final userStats = await _statsRepository.getUserStats(userId);
      if (userStats == null) return;

      final resetStats = PointsService.checkAndResetDaily(userStats);
      if (resetStats.totalPointsToday != userStats.totalPointsToday) {
        await _statsRepository.updateUserStats(resetStats);
      }
    } catch (e) {
      LogService.error('Error checking daily points reset',
          error: e, tag: 'HabitsBloc');
    }
  }

  Future<void> _awardPointsForHabit(Habit habit) async {
    try {
      final userId = FirebaseService().currentUserId;
      if (userId == null) return;

      final pointsToAward = habit.pointsValue ?? 0;
      if (pointsToAward <= 0) return;

      final userStats = await _statsRepository.getUserStats(userId);
      if (userStats == null) return;

      final newTotal = PointsService.awardPoints(
        userStats: userStats,
        pointsToAward: pointsToAward,
      );

      await _statsRepository.updateUserStats(
        userStats.copyWith(totalPointsToday: newTotal),
      );

      LogService.info(
          'Awarded $pointsToAward points for completing ${habit.name}',
          tag: 'HabitsBloc');
    } catch (e) {
      LogService.error('Error awarding points', error: e, tag: 'HabitsBloc');
    }
  }

  Future<void> _deductPointsForHabit(Habit habit) async {
    try {
      final userId = FirebaseService().currentUserId;
      if (userId == null) return;

      final pointsToDeduct = habit.pointsValue ?? 0;
      if (pointsToDeduct <= 0) return;

      final userStats = await _statsRepository.getUserStats(userId);
      if (userStats == null) return;

      final newTotal = PointsService.deductPoints(
        userStats: userStats,
        pointsToDeduct: pointsToDeduct,
      );

      await _statsRepository.updateUserStats(
        userStats.copyWith(totalPointsToday: newTotal),
      );

      LogService.info(
          'Deducted $pointsToDeduct points for uncompleting ${habit.name}',
          tag: 'HabitsBloc');
    } catch (e) {
      LogService.error('Error deducting points', error: e, tag: 'HabitsBloc');
    }
  }

  Future<void> _onPointsManuallyAdjusted(
    PointsManuallyAdjusted event,
    Emitter<HabitsState> emit,
  ) async {
    try {
      final userId = FirebaseService().currentUserId;
      if (userId == null) return;

      final userStats = await _statsRepository.getUserStats(userId);
      if (userStats == null) return;

      final newTotal = PointsService.manualAdjustPoints(
        userStats: userStats,
        delta: event.delta,
      );

      await _statsRepository.updateUserStats(
        userStats.copyWith(totalPointsToday: newTotal),
      );

      // Emit current state to trigger UI refresh
      if (state is HabitsLoaded) {
        emit(HabitsLoaded((state as HabitsLoaded).habits));
      }

      LogService.info('Manually adjusted points by ${event.delta}',
          tag: 'HabitsBloc');
    } catch (e) {
      LogService.error('Error manually adjusting points',
          error: e, tag: 'HabitsBloc');
    }
  }

  Future<void> _onPointRewardDescriptionUpdated(
    PointRewardDescriptionUpdated event,
    Emitter<HabitsState> emit,
  ) async {
    try {
      final userId = FirebaseService().currentUserId;
      if (userId == null) return;

      final userStats = await _statsRepository.getUserStats(userId);
      if (userStats == null) return;

      await _statsRepository.updateUserStats(
        userStats.copyWith(pointRewardDescription: event.description),
      );

      LogService.info('Updated point reward description', tag: 'HabitsBloc');
    } catch (e) {
      LogService.error('Error updating reward description',
          error: e, tag: 'HabitsBloc');
    }
  }
}
