import 'dart:async';
import '../../habits/domain/entities/habit.dart';

abstract class IHabitRepository {
  Stream<List<Habit>> watchHabits();
  Future<void> addHabit(Habit habit);
  Future<void> toggleHabit(String id, DateTime now);
}

class InMemoryHabitRepository implements IHabitRepository {
  final _controller = StreamController<List<Habit>>.broadcast();
  final List<Habit> _habits = [
    const Habit(id: '1', name: 'Morning Run', category: 'Health'),
    const Habit(id: '2', name: 'Read 20 mins', category: 'Learning'),
  ];

  InMemoryHabitRepository() {
    _emit();
  }

  void _emit() => _controller.add(List.unmodifiable(_habits));

  @override
  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    _emit();
  }

  @override
  Stream<List<Habit>> watchHabits() => _controller.stream;

  @override
  Future<void> toggleHabit(String id, DateTime now) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;
    final habit = _habits[index];
    _habits[index] = habit.copyWith(isCompletedToday: !habit.isCompletedToday);
    _emit();
  }
}
