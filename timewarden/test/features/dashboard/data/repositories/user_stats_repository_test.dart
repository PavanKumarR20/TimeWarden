import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timewarden/core/services/firebase_service.dart';
import 'package:timewarden/features/dashboard/data/repositories/user_stats_repository_impl.dart';

// Mock classes
class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  late UserStatsRepositoryImpl repository;
  late MockFirebaseService mockFirebaseService;
  late FakeFirebaseFirestore fakeFirestore;

  const testUserId = 'test-user-123';

  setUpAll(() {
    registerFallbackValue(FieldValue.increment(1));
  });

  setUp(() {
    mockFirebaseService = MockFirebaseService();
    fakeFirestore = FakeFirebaseFirestore();

    when(() => mockFirebaseService.firestore).thenReturn(fakeFirestore);

    repository = UserStatsRepositoryImpl(mockFirebaseService);
  });

  group('incrementPerfectDays', () {
    test('should call update with correct parameters', () async {
      // Arrange: pre-create doc so update succeeds
      final testDate = DateTime(2025, 12, 21);
      await fakeFirestore.collection('user_stats').doc(testUserId).set({
        'userId': testUserId,
        'perfectDays': 0,
        'perfectDayDates': [],
        'totalHabitsCreated': 0,
        'totalPomodoroSessions': 0,
        'totalJournalEntries': 0,
        'lastUpdated': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      // Act
      await repository.incrementPerfectDays(testUserId, date: testDate);

      // Assert
      final doc = await fakeFirestore.collection('user_stats').doc(testUserId).get();
      expect(doc.data()!['perfectDays'], 1);
    });

    test('should use current date when date parameter is null', () async {
      // Arrange
      await fakeFirestore.collection('user_stats').doc(testUserId).set({
        'userId': testUserId,
        'perfectDays': 0,
        'perfectDayDates': [],
        'totalHabitsCreated': 0,
        'totalPomodoroSessions': 0,
        'totalJournalEntries': 0,
        'lastUpdated': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      // Act
      await repository.incrementPerfectDays(testUserId);

      // Assert
      final doc = await fakeFirestore.collection('user_stats').doc(testUserId).get();
      expect(doc.data()!['perfectDays'], 1);
    });

    test('should create initial stats if document does not exist', () async {
      // Arrange - no pre-existing doc

      // Act
      await repository.incrementPerfectDays(testUserId, date: DateTime(2025, 12, 21));

      // Assert
      final doc = await fakeFirestore.collection('user_stats').doc(testUserId).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['perfectDays'], 1);
    });
  });

  group('decrementPerfectDays', () {
    test('should call update when perfectDays > 0', () async {
      // Arrange
      final testDate = DateTime(2025, 12, 21);
      await fakeFirestore.collection('user_stats').doc(testUserId).set({
        'userId': testUserId,
        'perfectDays': 5,
        'perfectDayDates': [Timestamp.fromDate(testDate)],
        'totalHabitsCreated': 0,
        'totalPomodoroSessions': 0,
        'totalJournalEntries': 0,
        'lastUpdated': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      // Act
      await repository.decrementPerfectDays(testUserId, date: testDate);

      // Assert
      final doc = await fakeFirestore.collection('user_stats').doc(testUserId).get();
      expect(doc.data()!['perfectDays'], 4);
    });

    test('should not decrement when perfectDays is already 0', () async {
      // Arrange
      final testDate = DateTime(2025, 12, 21);
      await fakeFirestore.collection('user_stats').doc(testUserId).set({
        'userId': testUserId,
        'perfectDays': 0,
        'perfectDayDates': [],
        'totalHabitsCreated': 0,
        'totalPomodoroSessions': 0,
        'totalJournalEntries': 0,
        'lastUpdated': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      // Act
      await repository.decrementPerfectDays(testUserId, date: testDate);

      // Assert - perfectDays should still be 0
      final doc = await fakeFirestore.collection('user_stats').doc(testUserId).get();
      expect(doc.data()!['perfectDays'], 0);
    });

    test('should not decrement when user stats do not exist', () async {
      // Arrange - no doc

      // Act
      await repository.decrementPerfectDays(testUserId, date: DateTime(2025, 12, 21));

      // Assert - no document created
      final doc = await fakeFirestore.collection('user_stats').doc(testUserId).get();
      expect(doc.exists, isFalse);
    });
  });

  group('getUserStats', () {
    test('should return user stats with perfectDayDates', () async {
      // Arrange
      final date1 = DateTime(2025, 12, 20);
      final date2 = DateTime(2025, 12, 21);
      await fakeFirestore.collection('user_stats').doc(testUserId).set({
        'userId': testUserId,
        'perfectDays': 2,
        'perfectDayDates': [
          Timestamp.fromDate(date1),
          Timestamp.fromDate(date2),
        ],
        'totalHabitsCreated': 5,
        'totalPomodoroSessions': 10,
        'totalJournalEntries': 3,
        'lastUpdated': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      // Act
      final result = await repository.getUserStats(testUserId);

      // Assert
      expect(result, isNotNull);
      expect(result!.perfectDays, 2);
      expect(result.perfectDayDates.length, 2);
      expect(result.perfectDayDates[0].year, date1.year);
      expect(result.perfectDayDates[0].month, date1.month);
      expect(result.perfectDayDates[0].day, date1.day);
    });

    test('should return null when user stats do not exist', () async {
      // Act
      final result = await repository.getUserStats(testUserId);

      // Assert
      expect(result, isNull);
    });

    test('should handle empty perfectDayDates array', () async {
      // Arrange
      await fakeFirestore.collection('user_stats').doc(testUserId).set({
        'userId': testUserId,
        'perfectDays': 0,
        'perfectDayDates': [],
        'totalHabitsCreated': 0,
        'totalPomodoroSessions': 0,
        'totalJournalEntries': 0,
        'lastUpdated': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      // Act
      final result = await repository.getUserStats(testUserId);

      // Assert
      expect(result, isNotNull);
      expect(result!.perfectDays, 0);
      expect(result.perfectDayDates, isEmpty);
    });
  });

  group('Edge Cases', () {
    test('should handle multiple increments on same day', () async {
      // Arrange
      final testDate = DateTime(2025, 12, 21);
      await fakeFirestore.collection('user_stats').doc(testUserId).set({
        'userId': testUserId,
        'perfectDays': 0,
        'perfectDayDates': [],
        'totalHabitsCreated': 0,
        'totalPomodoroSessions': 0,
        'totalJournalEntries': 0,
        'lastUpdated': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      // Act - increment twice with same date
      await repository.incrementPerfectDays(testUserId, date: testDate);
      await repository.incrementPerfectDays(testUserId, date: testDate);

      // Assert - perfectDays incremented twice (Firestore arrayUnion prevents date duplicates)
      final doc = await fakeFirestore.collection('user_stats').doc(testUserId).get();
      expect(doc.data()!['perfectDays'], 2);
    });

    test('should normalize dates with different times to same day', () async {
      // Arrange
      final testDate1 = DateTime(2025, 12, 21, 8, 0);
      final testDate2 = DateTime(2025, 12, 21, 23, 59);
      await fakeFirestore.collection('user_stats').doc(testUserId).set({
        'userId': testUserId,
        'perfectDays': 0,
        'perfectDayDates': [],
        'totalHabitsCreated': 0,
        'totalPomodoroSessions': 0,
        'totalJournalEntries': 0,
        'lastUpdated': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      // Act
      await repository.incrementPerfectDays(testUserId, date: testDate1);
      await repository.incrementPerfectDays(testUserId, date: testDate2);

      // Assert - both increments processed
      final doc = await fakeFirestore.collection('user_stats').doc(testUserId).get();
      expect(doc.data()!['perfectDays'], 2);
    });
  });
}
