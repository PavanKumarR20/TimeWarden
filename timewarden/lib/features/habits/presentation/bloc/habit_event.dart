part of 'habit_bloc.dart';

abstract class HabitEvent {}

class LoadHabits extends HabitEvent {}

class ToggleHabit extends HabitEvent {
  final String id;
  ToggleHabit(this.id);
}
