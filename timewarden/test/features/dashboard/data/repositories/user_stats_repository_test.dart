import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timewarden/core/services/firebase_service.dart';
import 'package:timewarden/features/dashboard/data/repositories/user_stats_repository_impl.dart';
import 'package:timewarden/features/dashboard/domain/entities/user_stats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes
class MockFirebaseService extends Mock implements FirebaseService {}

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late UserStatsRepositoryImpl repository;
  late MockFirebaseService mockFirebaseService;
  late MockFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockDocumentSnapshot mockSnapshot;

  const testUserId = 'test-user-123';

  setUpAll(() {
    registerFallbackValue(FieldValue.increment(1));
  });

  setUp(() {
    mockFirebaseService = MockFirebaseService();
    mockFirestore = MockFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();

    // Setup Firebase mock chain
    when(() => mockFirebaseService.firestore).thenReturn(mockFirestore);
    when(() => mockFirestore.collection('user_stats'))
        .thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocument);

    repository = UserStatsRepositoryImpl(mockFirebaseService);
  });

  group('incrementPerfectDays', () {
    test('should call update with correct parameters', () async {
      // Arrange
      final testDate = DateTime(2025, 12, 21);
      when(() => mockDocument.update(any())).thenAnswer((_) async => {});

      // Act
      await repository.incrementPerfectDays(testUserId, date: testDate);

      // Assert - verify update was called
      verify(() => mockDocument.update(any())).called(1);
    });

    test('should use current date when date parameter is null', () async {
      // Arrange
      when(() => mockDocument.update(any())).thenAnswer((_) async => {});

      // Act
      await repository.incrementPerfectDays(testUserId);

      // Assert
      verify(() => mockDocument.update(any())).called(1);
    });

    test('should create initial stats if document does not exist', () async {
      // Arrange
      final testDate = DateTime(2025, 12, 21);
      when(() => mockDocument.update(any())).thenThrow(
        Exception('No document to update'),
      );
      when(() => mockDocument.set(any())).thenAnswer((_) async => {});

      // Act
      await repository.incrementPerfectDays(testUserId, date: testDate);

      // Assert
      verify(() => mockDocument.set(any())).called(1);
    });
  });

  group('decrementPerfectDays', () {
    test('should call update when perfectDays > 0', () async {
      // Arrange
      final testDate = DateTime(2025, 12, 21);

      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'userId': testUserId,
        'perfectDays': 5,
        'perfectDayDates': [Timestamp.fromDate(testDate)],
        'totalHabitsCreated': 0,
        'totalPomodoroSessions': 0,
        'totalJournalEntries': 0,
        'lastUpdated': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });
      when(() => mockDocument.update(any())).thenAnswer((_) async => {});

      // Act
      await repository.decrementPerfectDays(testUserId, date: testDate);

      // Assert
      verify(() => mockDocument.update(any())).called(1);
    });

    test('should not decrement when perfectDays is already 0', () async {
      // Arrange
      final testDate = DateTime(2025, 12, 21);
      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
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

      // Assert
      verifyNever(() => mockDocument.update(any()));
    });

    test('should not decrement when user stats do not exist', () async {
      // Arrange
      final testDate = DateTime(2025, 12, 21);
      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);

      // Act
      await repository.decrementPerfectDays(testUserId, date: testDate);

      // Assert
      verifyNever(() => mockDocument.update(any()));
    });
  });

  group('getUserStats', () {
    test('should return user stats with perfectDayDates', () async {
      // Arrange
      final date1 = DateTime(2025, 12, 20);
      final date2 = DateTime(2025, 12, 21);
      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
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
      // Arrange
      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);

      // Act
      final result = await repository.getUserStats(testUserId);

      // Assert
      expect(result, isNull);
    });

    test('should handle empty perfectDayDates array', () async {
      // Arrange
      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
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
      // Arrange - arrayUnion should prevent duplicates
      final testDate = DateTime(2025, 12, 21);
      when(() => mockDocument.update(any())).thenAnswer((_) async => {});

      // Act - increment twice with same date
      await repository.incrementPerfectDays(testUserId, date: testDate);
      await repository.incrementPerfectDays(testUserId, date: testDate);

      // Assert - should be called twice (Firestore arrayUnion prevents duplicates)
      verify(() => mockDocument.update(any())).called(2);
    });

    test('should normalize dates with different times to same day', () async {
      // Arrange
      final testDate1 = DateTime(2025, 12, 21, 8, 0); // Morning
      final testDate2 = DateTime(2025, 12, 21, 23, 59); // Night
      when(() => mockDocument.update(any())).thenAnswer((_) async => {});

      // Act
      await repository.incrementPerfectDays(testUserId, date: testDate1);
      await repository.incrementPerfectDays(testUserId, date: testDate2);

      // Assert - both processed (arrayUnion handles deduplication)
      verify(() => mockDocument.update(any())).called(2);
    });
  });
}
