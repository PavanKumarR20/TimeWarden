import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/log_service.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/repositories/user_stats_repository.dart';

class UserStatsRepositoryImpl implements UserStatsRepository {
  final FirebaseService _firebaseService;

  UserStatsRepositoryImpl(this._firebaseService);

  CollectionReference get _statsCollection =>
      _firebaseService.firestore.collection('user_stats');

  @override
  Future<UserStats?> getUserStats(String userId) async {
    LogService.debug('Getting user stats for: $userId',
        tag: 'UserStatsRepository');

    try {
      final doc = await _statsCollection.doc(userId).get();

      if (!doc.exists) {
        LogService.debug('No stats found for user: $userId',
            tag: 'UserStatsRepository');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      
      // UserStats.fromJson now handles Timestamp conversion internally
      final stats = UserStats.fromJson(data);
      LogService.debug('Retrieved stats: ${stats.perfectDays} perfect days',
          tag: 'UserStatsRepository');
      return stats;
    } catch (e) {
      LogService.error('Error getting user stats',
          error: e, tag: 'UserStatsRepository');
      return null;
    }
  }

  @override
  Future<void> saveUserStats(UserStats stats) async {
    LogService.debug('Saving user stats for: ${stats.userId}',
        tag: 'UserStatsRepository');

    try {
      final data = _convertToFirestoreData(stats);
      await _statsCollection.doc(stats.userId).set(data);
      LogService.debug('Successfully saved user stats',
          tag: 'UserStatsRepository');
    } catch (e) {
      LogService.error('Error saving user stats',
          error: e, tag: 'UserStatsRepository');
      rethrow;
    }
  }

  @override
  Future<void> updateUserStats(UserStats stats) async {
    LogService.debug('Updating user stats for: ${stats.userId}',
        tag: 'UserStatsRepository');

    try {
      final data = _convertToFirestoreData(stats);
      await _statsCollection.doc(stats.userId).update(data);
      LogService.debug('Successfully updated user stats',
          tag: 'UserStatsRepository');
    } catch (e) {
      LogService.error('Error updating user stats',
          error: e, tag: 'UserStatsRepository');
      rethrow;
    }
  }

  @override
  Future<void> incrementPerfectDays(String userId, {DateTime? date}) async {
    final perfectDate = date ?? DateTime.now();
    final dateOnly =
        DateTime(perfectDate.year, perfectDate.month, perfectDate.day);

    LogService.debug('Incrementing perfect days for: $userId on $dateOnly',
        tag: 'UserStatsRepository');

    try {
      await _statsCollection.doc(userId).update({
        'perfectDays': FieldValue.increment(1),
        'perfectDayDates':
            FieldValue.arrayUnion([Timestamp.fromDate(dateOnly)]),
        'lastUpdated': Timestamp.now(),
      });
      LogService.debug('Successfully incremented perfect days',
          tag: 'UserStatsRepository');
    } catch (e) {
      LogService.error('Error incrementing perfect days',
          error: e, tag: 'UserStatsRepository');

      // If document doesn't exist, create it
      if (e.toString().contains('No document to update') ||
          e.toString().contains('not-found') ||
          e.toString().contains('Some requested document was not found')) {
        LogService.debug(
            'Document not found, creating initial stats with 1 perfect day',
            tag: 'UserStatsRepository');
        await _createInitialStats(userId,
            perfectDays: 1, perfectDayDates: [dateOnly]);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> decrementPerfectDays(String userId, {DateTime? date}) async {
    final perfectDate = date ?? DateTime.now();
    final dateOnly =
        DateTime(perfectDate.year, perfectDate.month, perfectDate.day);

    LogService.debug('Decrementing perfect days for: $userId on $dateOnly',
        tag: 'UserStatsRepository');

    try {
      // Get current stats to ensure we don't go below 0
      final currentStats = await getUserStats(userId);
      if (currentStats == null || currentStats.perfectDays <= 0) {
        LogService.debug('Perfect days already at 0, not decrementing',
            tag: 'UserStatsRepository');
        return;
      }

      await _statsCollection.doc(userId).update({
        'perfectDays': FieldValue.increment(-1),
        'perfectDayDates':
            FieldValue.arrayRemove([Timestamp.fromDate(dateOnly)]),
        'lastUpdated': Timestamp.now(),
      });
      LogService.debug('Successfully decremented perfect days',
          tag: 'UserStatsRepository');
    } catch (e) {
      LogService.error('Error decrementing perfect days',
          error: e, tag: 'UserStatsRepository');
      rethrow;
    }
  }

  @override
  Future<void> incrementHabitsCreated(String userId) async {
    LogService.debug('Incrementing habits created for: $userId',
        tag: 'UserStatsRepository');

    try {
      await _statsCollection.doc(userId).update({
        'totalHabitsCreated': FieldValue.increment(1),
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      if (e.toString().contains('No document to update')) {
        await _createInitialStats(userId, totalHabitsCreated: 1);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> incrementPomodoroSessions(String userId) async {
    LogService.debug('Incrementing pomodoro sessions for: $userId',
        tag: 'UserStatsRepository');

    try {
      await _statsCollection.doc(userId).update({
        'totalPomodoroSessions': FieldValue.increment(1),
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      if (e.toString().contains('No document to update')) {
        await _createInitialStats(userId, totalPomodoroSessions: 1);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> incrementJournalEntries(String userId) async {
    LogService.debug('Incrementing journal entries for: $userId',
        tag: 'UserStatsRepository');

    try {
      await _statsCollection.doc(userId).update({
        'totalJournalEntries': FieldValue.increment(1),
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      if (e.toString().contains('No document to update')) {
        await _createInitialStats(userId, totalJournalEntries: 1);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _createInitialStats(
    String userId, {
    int perfectDays = 0,
    List<DateTime>? perfectDayDates,
    int totalHabitsCreated = 0,
    int totalPomodoroSessions = 0,
    int totalJournalEntries = 0,
  }) async {
    print(
        '🆕 CREATING INITIAL STATS for user: $userId with perfectDays: $perfectDays');
    LogService.debug(
        'Creating initial stats for user: $userId with perfectDays: $perfectDays',
        tag: 'UserStatsRepository');

    final now = DateTime.now();
    final stats = UserStats(
      userId: userId,
      perfectDays: perfectDays,
      perfectDayDates: perfectDayDates ?? [],
      totalHabitsCreated: totalHabitsCreated,
      totalPomodoroSessions: totalPomodoroSessions,
      totalJournalEntries: totalJournalEntries,
      lastUpdated: now,
      createdAt: now,
    );

    print('💾 Saving initial stats to Firestore...');
    await saveUserStats(stats);
    print('✅ Initial stats saved successfully!');
  }

  Map<String, dynamic> _convertToFirestoreData(UserStats stats) {
    final data = stats.toJson();

    // Convert DateTime strings back to Timestamps for Firestore
    data['lastUpdated'] =
        Timestamp.fromDate(DateTime.parse(data['lastUpdated']));
    data['createdAt'] = Timestamp.fromDate(DateTime.parse(data['createdAt']));

    return data;
  }
}
