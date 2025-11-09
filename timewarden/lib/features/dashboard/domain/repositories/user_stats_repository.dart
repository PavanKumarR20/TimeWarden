import '../entities/user_stats.dart';

abstract class UserStatsRepository {
  Future<UserStats?> getUserStats(String userId);
  Future<void> saveUserStats(UserStats stats);
  Future<void> updateUserStats(UserStats stats);
  Future<void> incrementPerfectDays(String userId, {DateTime? date});
  Future<void> decrementPerfectDays(String userId, {DateTime? date});
  Future<void> incrementHabitsCreated(String userId);
  Future<void> incrementPomodoroSessions(String userId);
  Future<void> incrementJournalEntries(String userId);
}
