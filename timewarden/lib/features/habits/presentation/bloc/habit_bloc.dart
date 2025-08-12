import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/habit.dart';
import '../../data/habit_repository.dart';

part 'habit_event.dart';
part 'habit_state.dart';

class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final IHabitRepository habitRepository;

  HabitBloc({required this.habitRepository})
      : super(const HabitState.loading()) {
    on<LoadHabits>(_onLoadHabits);
    on<ToggleHabit>(_onToggleHabit);
  }

  Future<void> _onLoadHabits(LoadHabits event, Emitter<HabitState> emit) async {
    emit(const HabitState.loading());
    await emit.forEach<List<Habit>>(habitRepository.watchHabits(),
        onData: (habits) => HabitState.loaded(habits));
  }

  Future<void> _onToggleHabit(
      ToggleHabit event, Emitter<HabitState> emit) async {
    await habitRepository.toggleHabit(event.id, DateTime.now());
  }
}
