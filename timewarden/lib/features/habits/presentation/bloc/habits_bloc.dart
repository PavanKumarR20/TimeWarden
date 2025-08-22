import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../../../core/services/log_service.dart';

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

  HabitsBloc(this._habitRepository) : super(HabitsInitial()) {
    on<HabitsLoadRequested>(_onHabitsLoadRequested);
    on<HabitAdded>(_onHabitAdded);
    on<HabitUpdated>(_onHabitUpdated);
    on<HabitDeleted>(_onHabitDeleted);
    on<HabitCompletionToggled>(_onHabitCompletionToggled);
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

        // Emit the updated state immediately for instant UI feedback
        emit(HabitsLoaded(updatedHabits));

        // Then update the backend asynchronously
        if (isCompleted) {
          await _habitRepository.markHabitIncomplete(event.habitId, event.date);
        } else {
          await _habitRepository.markHabitComplete(event.habitId, event.date);
        }

        LogService.debug('Habit completion toggled successfully in backend',
            tag: 'HabitsBloc');
      }
    } catch (e) {
      LogService.error('Error toggling habit completion',
          tag: 'HabitsBloc', error: e);
      // Reload the data to sync with backend if there's an error
      add(HabitsLoadRequested());
      emit(HabitsError(e.toString()));
    }
  }
}
