import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/log_service.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/repositories/pomodoro_repository.dart';

class PomodoroRepositoryImpl implements PomodoroRepository {
  final FirebaseService _firebaseService;

  PomodoroRepositoryImpl(this._firebaseService);

  CollectionReference _getSessionsCollection() {
    final userId = _firebaseService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firebaseService.firestore
        .collection('users')
        .doc(userId)
        .collection('pomodoro_sessions');
  }

  @override
  Future<List<PomodoroSession>> getSessions() async {
    final userId = _firebaseService.currentUserId;
    LogService.debug('Getting Pomodoro sessions for user: $userId',
        tag: 'PomodoroRepository');

    if (userId == null) {
      LogService.warning('User not authenticated, returning empty list',
          tag: 'PomodoroRepository');
      return <PomodoroSession>[];
    }

    try {
      final snapshot = await _getSessionsCollection()
          .orderBy('startTime', descending: true)
          .limit(1000) // Reasonable limit
          .get();

      LogService.debug('Retrieved ${snapshot.docs.length} Pomodoro sessions',
          tag: 'PomodoroRepository');

      final sessions = <PomodoroSession>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          // Convert Firestore Timestamps to ISO strings for PomodoroSession.fromJson
          _convertTimestampsToStrings(data);

          final session = PomodoroSession.fromJson(data);
          sessions.add(session);
        } catch (e) {
          LogService.error('Error parsing Pomodoro session: ${doc.id}',
              error: e, tag: 'PomodoroRepository');
        }
      }

      return sessions;
    } catch (e) {
      LogService.error('Error getting Pomodoro sessions',
          error: e, tag: 'PomodoroRepository');
      return <PomodoroSession>[];
    }
  }

  @override
  Future<List<PomodoroSession>> getSessionsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getSessionsForDateRange(startOfDay, endOfDay);
  }

  @override
  Future<List<PomodoroSession>> getSessionsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = _firebaseService.currentUserId;
    LogService.debug(
        'Getting Pomodoro sessions from $startDate to $endDate for user: $userId',
        tag: 'PomodoroRepository');

    if (userId == null) {
      LogService.warning('User not authenticated, returning empty list',
          tag: 'PomodoroRepository');
      return <PomodoroSession>[];
    }

    try {
      final snapshot = await _getSessionsCollection()
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('startTime', descending: true)
          .get();

      LogService.debug(
          'Retrieved ${snapshot.docs.length} Pomodoro sessions for date range',
          tag: 'PomodoroRepository');

      final sessions = <PomodoroSession>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          // Convert Firestore Timestamps to ISO strings for PomodoroSession.fromJson
          _convertTimestampsToStrings(data);

          final session = PomodoroSession.fromJson(data);
          sessions.add(session);
        } catch (e) {
          LogService.error('Error parsing Pomodoro session: ${doc.id}',
              error: e, tag: 'PomodoroRepository');
        }
      }

      return sessions;
    } catch (e) {
      LogService.error('Error getting Pomodoro sessions for date range',
          error: e, tag: 'PomodoroRepository');
      return <PomodoroSession>[];
    }
  }

  @override
  Future<void> saveSession(PomodoroSession session) async {
    final userId = _firebaseService.currentUserId;
    LogService.debug('Saving Pomodoro session: ${session.id} for user: $userId',
        tag: 'PomodoroRepository');

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final data = _convertToFirestoreData(session);

      await _getSessionsCollection().doc(session.id).set(data);

      LogService.debug('Successfully saved Pomodoro session: ${session.id}',
          tag: 'PomodoroRepository');
    } catch (e) {
      LogService.error('Error saving Pomodoro session: ${session.id}',
          error: e, tag: 'PomodoroRepository');
      rethrow;
    }
  }

  @override
  Future<void> updateSession(PomodoroSession session) async {
    final userId = _firebaseService.currentUserId;
    LogService.debug(
        'Updating Pomodoro session: ${session.id} for user: $userId',
        tag: 'PomodoroRepository');

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final data = _convertToFirestoreData(session);

      await _getSessionsCollection().doc(session.id).update(data);

      LogService.debug('Successfully updated Pomodoro session: ${session.id}',
          tag: 'PomodoroRepository');
    } catch (e) {
      LogService.error('Error updating Pomodoro session: ${session.id}',
          error: e, tag: 'PomodoroRepository');
      rethrow;
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final userId = _firebaseService.currentUserId;
    LogService.debug('Deleting Pomodoro session: $sessionId for user: $userId',
        tag: 'PomodoroRepository');

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _getSessionsCollection().doc(sessionId).delete();

      LogService.debug('Successfully deleted Pomodoro session: $sessionId',
          tag: 'PomodoroRepository');
    } catch (e) {
      LogService.error('Error deleting Pomodoro session: $sessionId',
          error: e, tag: 'PomodoroRepository');
      rethrow;
    }
  }

  @override
  Future<int> getSessionCount() async {
    final userId = _firebaseService.currentUserId;
    LogService.debug('Getting Pomodoro session count for user: $userId',
        tag: 'PomodoroRepository');

    if (userId == null) {
      return 0;
    }

    try {
      final snapshot = await _getSessionsCollection().count().get();
      final count = snapshot.count ?? 0;

      LogService.debug('Total Pomodoro sessions: $count',
          tag: 'PomodoroRepository');
      return count;
    } catch (e) {
      LogService.error('Error getting Pomodoro session count',
          error: e, tag: 'PomodoroRepository');
      return 0;
    }
  }

  @override
  Future<void> clearAllSessions() async {
    final userId = _firebaseService.currentUserId;
    LogService.debug('Clearing all Pomodoro sessions for user: $userId',
        tag: 'PomodoroRepository');

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _getSessionsCollection().get();

      // Delete in batch
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      LogService.debug('Successfully cleared all Pomodoro sessions',
          tag: 'PomodoroRepository');
    } catch (e) {
      LogService.error('Error clearing Pomodoro sessions',
          error: e, tag: 'PomodoroRepository');
      rethrow;
    }
  }

  /// Convert Firestore Timestamps to ISO strings for PomodoroSession.fromJson
  void _convertTimestampsToStrings(Map<String, dynamic> data) {
    if (data['startTime'] is Timestamp) {
      data['startTime'] =
          (data['startTime'] as Timestamp).toDate().toIso8601String();
    }
    if (data['endTime'] is Timestamp) {
      data['endTime'] =
          (data['endTime'] as Timestamp).toDate().toIso8601String();
    }
    if (data['pausedAt'] is List) {
      final pausedList = data['pausedAt'] as List;
      data['pausedAt'] = pausedList.map((timestamp) {
        if (timestamp is Timestamp) {
          return timestamp.toDate().toIso8601String();
        }
        return timestamp;
      }).toList();
    }
    if (data['resumedAt'] is List) {
      final resumedList = data['resumedAt'] as List;
      data['resumedAt'] = resumedList.map((timestamp) {
        if (timestamp is Timestamp) {
          return timestamp.toDate().toIso8601String();
        }
        return timestamp;
      }).toList();
    }
  }

  /// Convert DateTime to Timestamp for Firestore storage
  Map<String, dynamic> _convertToFirestoreData(PomodoroSession session) {
    final data = session.toJson();
    data.remove('id'); // Remove ID from data

    // Convert ISO strings back to Timestamps
    if (data['startTime'] is String) {
      data['startTime'] =
          Timestamp.fromDate(DateTime.parse(data['startTime'] as String));
    }
    if (data['endTime'] is String) {
      data['endTime'] =
          Timestamp.fromDate(DateTime.parse(data['endTime'] as String));
    }
    if (data['pausedAt'] is List) {
      final pausedList = data['pausedAt'] as List;
      data['pausedAt'] = pausedList.map((isoString) {
        if (isoString is String) {
          return Timestamp.fromDate(DateTime.parse(isoString));
        }
        return isoString;
      }).toList();
    }
    if (data['resumedAt'] is List) {
      final resumedList = data['resumedAt'] as List;
      data['resumedAt'] = resumedList.map((isoString) {
        if (isoString is String) {
          return Timestamp.fromDate(DateTime.parse(isoString));
        }
        return isoString;
      }).toList();
    }

    return data;
  }
}
