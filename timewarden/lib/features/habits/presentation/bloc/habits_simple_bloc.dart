import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';

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

// BLoC - Much simpler with get() approach
class HabitsSimpleBloc extends Bloc<HabitsEvent, HabitsState> {
  final HabitRepository _habitRepository;

  HabitsSimpleBloc(this._habitRepository) : super(HabitsInitial()) {
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
    print('HabitsBloc: Load requested');
    emit(HabitsLoading());

    try {
      // Simple one-time fetch
      final habits = await _habitRepository.getHabits();
      print('HabitsBloc: Received ${habits.length} habits');
      emit(HabitsLoaded(habits));
    } catch (e) {
      print('HabitsBloc: Error loading habits: $e');
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> _onHabitAdded(
    HabitAdded event,
    Emitter<HabitsState> emit,
  ) async {
    try {
      await _habitRepository.addHabit(event.habit);
      // Refresh the list after adding
      add(HabitsLoadRequested());
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> _onHabitUpdated(
    HabitUpdated event,
    Emitter<HabitsState> emit,
  ) async {
    try {
      await _habitRepository.updateHabit(event.habit);
      // Refresh the list after updating
      add(HabitsLoadRequested());
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> _onHabitDeleted(
    HabitDeleted event,
    Emitter<HabitsState> emit,
  ) async {
    try {
      await _habitRepository.deleteHabit(event.habitId);
      // Refresh the list after deleting
      add(HabitsLoadRequested());
    } catch (e) {
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
        final habit = currentState.habits.firstWhere(
          (h) => h.id == event.habitId,
        );

        final dateOnly =
            DateTime(event.date.year, event.date.month, event.date.day);
        final isCompleted = habit.completedDates.any((date) =>
            date.year == dateOnly.year &&
            date.month == dateOnly.month &&
            date.day == dateOnly.day);

        if (isCompleted) {
          await _habitRepository.markHabitIncomplete(event.habitId, event.date);
        } else {
          await _habitRepository.markHabitComplete(event.habitId, event.date);
        }

        // Refresh the list after toggling completion
        add(HabitsLoadRequested());
      }
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }
}
