part of 'habit_bloc.dart';

class HabitState extends Equatable {
  final List<Habit> habits;
  final bool isLoading;
  const HabitState._(this.habits, this.isLoading);
  const HabitState.loading() : this._(const [], true);
  const HabitState.loaded(List<Habit> habits) : this._(habits, false);

  @override
  List<Object?> get props => [habits, isLoading];
}
