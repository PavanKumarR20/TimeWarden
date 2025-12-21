import 'package:mocktail/mocktail.dart';
import 'package:timewarden/features/habits/domain/repositories/habit_repository.dart';
import 'package:timewarden/features/habits/domain/entities/habit.dart';

// Mock repository for testing
class MockHabitRepository extends Mock implements HabitRepository {}

// Test data helpers
class TestHabits {
  static final testHabit1 = Habit(
    id: 'test-1',
    name: 'Test Habit 1',
    category: HabitCategory.health,
    frequency: const HabitFrequency(
      type: HabitFrequencyType.daily,
      target: 1,
    ),
    createdAt: DateTime(2024, 1, 1),
    completedDates: [],
  );

  static final testHabit2 = Habit(
    id: 'test-2',
    name: 'Test Habit 2',
    category: HabitCategory.productivity,
    frequency: const HabitFrequency(
      type: HabitFrequencyType.timesPerWeek,
      target: 3,
    ),
    createdAt: DateTime(2024, 1, 1),
    completedDates: [
      DateTime(2024, 12, 20),
      DateTime(2024, 12, 19),
    ],
  );

  static List<Habit> get all => [testHabit1, testHabit2];
}
