import '../entities/goal.dart';

abstract class GoalRepository {
  Future<List<Goal>> getGoals();
  Future<Goal?> getGoalById(String id);
  Future<void> createGoal(Goal goal);
  Future<void> updateGoal(Goal goal);
  Future<void> deleteGoal(String id);
  Future<void> toggleGoalCompletion(String id);
  Future<List<Goal>> getCompletedGoals();
  Future<List<Goal>> getPendingGoals();
}
