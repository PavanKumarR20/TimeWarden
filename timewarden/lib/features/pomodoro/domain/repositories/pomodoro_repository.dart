import '../entities/pomodoro_session.dart';

abstract class PomodoroRepository {
  /// Get all Pomodoro sessions for the current user
  Future<List<PomodoroSession>> getSessions();

  /// Get Pomodoro sessions for a specific date
  Future<List<PomodoroSession>> getSessionsForDate(DateTime date);

  /// Get Pomodoro sessions for a date range
  Future<List<PomodoroSession>> getSessionsForDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Save a completed Pomodoro session
  Future<void> saveSession(PomodoroSession session);

  /// Update an existing Pomodoro session
  Future<void> updateSession(PomodoroSession session);

  /// Delete a Pomodoro session
  Future<void> deleteSession(String sessionId);

  /// Get the total count of sessions
  Future<int> getSessionCount();

  /// Clear all sessions (for testing/debugging)
  Future<void> clearAllSessions();
}
