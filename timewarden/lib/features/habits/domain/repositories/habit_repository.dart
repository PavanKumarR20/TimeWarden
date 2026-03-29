import '../entities/habit.dart';

abstract class HabitRepository {
  Future<List<Habit>> getHabits();
  Future<void> addHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(String habitId);
  Future<void> markHabitComplete(String habitId, DateTime date);
  Future<void> markHabitIncomplete(String habitId, DateTime date);
}
