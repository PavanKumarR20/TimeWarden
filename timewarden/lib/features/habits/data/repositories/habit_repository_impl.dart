import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/utils/security_utils.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';

class HabitRepositoryImpl implements HabitRepository {
  final FirebaseService _firebaseService;

  HabitRepositoryImpl(this._firebaseService);

  @override
  Future<List<Habit>> getHabits() async {
    final userId = _firebaseService.currentUserId;
    LogService.debug('Getting habits for user: $userId', tag: 'HabitRepository');

    if (userId == null) {
      LogService.warning('User not authenticated, returning empty list', tag: 'HabitRepository');
      return <Habit>[];
    }

    try {
      final snapshot = await _firebaseService.getUserHabits(userId).get();

      LogService.debug(
          'Received snapshot with ${snapshot.docs.length} documents', tag: 'HabitRepository');

      if (snapshot.docs.isEmpty) {
        LogService.debug('No habits found, returning empty list', tag: 'HabitRepository');
        return <Habit>[];
      }

      final habits = <Habit>[];
      for (final doc in snapshot.docs) {
        try {
          LogService.debug('Processing document: ${doc.id}', tag: 'HabitRepository');
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          final habit = Habit.fromJson(data);
          LogService.debug('Successfully parsed habit: ${habit.name}', tag: 'HabitRepository');
          habits.add(habit);
        } catch (e) {
          LogService.error('Error parsing habit ${doc.id}', tag: 'HabitRepository', error: e);
          // Skip this document instead of failing completely
          continue;
        }
      }

      LogService.debug('Returning ${habits.length} habits', tag: 'HabitRepository');
      return habits;
    } catch (e) {
      LogService.error('Error fetching habits', tag: 'HabitRepository', error: e);
      // Return empty list instead of throwing for common errors
      if (e.toString().contains('permission') ||
          e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('not found')) {
        LogService.warning('Returning empty list due to permission error', tag: 'HabitRepository');
        return <Habit>[];
      }
      rethrow;
    }
  }

  @override
  Future<void> addHabit(Habit habit) async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Security validation
    if (!SecurityUtils.isValidUserId(userId)) {
      throw Exception('Invalid user ID');
    }

    if (!SecurityUtils.isValidHabitName(habit.name)) {
      throw Exception('Invalid habit name');
    }

    // Rate limiting for habit creation
    if (!SecurityUtils.canPerformOperation('create_habit_$userId', cooldownSeconds: 2)) {
      throw Exception('Too many requests. Please wait before creating another habit.');
    }

    LogService.debug('Adding habit: ${habit.name} for user: $userId', tag: 'HabitRepository');

    final habitData = habit.toJson();
    habitData.remove('id'); // Let Firestore generate the ID

    await _firebaseService.getUserHabits(userId).add(habitData);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Security validation
    if (!SecurityUtils.isValidUserId(userId)) {
      throw Exception('Invalid user ID');
    }

    if (!SecurityUtils.isValidHabitName(habit.name)) {
      throw Exception('Invalid habit name');
    }

    if (habit.id.isEmpty) {
      throw Exception('Invalid habit ID');
    }

    // Rate limiting for habit updates
    if (!SecurityUtils.canPerformOperation('update_habit_$userId', cooldownSeconds: 1)) {
      throw Exception('Too many requests. Please wait before updating again.');
    }

    LogService.debug('Updating habit: ${habit.name} for user: $userId', tag: 'HabitRepository');

    final habitData = habit.toJson();
    habitData.remove('id'); // Remove ID before updating

    await _firebaseService.getUserHabits(userId).doc(habit.id).update(habitData);
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _firebaseService.getUserHabits(userId).doc(habitId).delete();
  }

  @override
  Future<void> markHabitComplete(String habitId, DateTime date) async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final habitRef = _firebaseService.getUserHabits(userId).doc(habitId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final habitSnapshot = await transaction.get(habitRef);
      if (!habitSnapshot.exists) throw Exception('Habit not found');

      final habitData = habitSnapshot.data() as Map<String, dynamic>;
      habitData['id'] = habitSnapshot.id;
      final habit = Habit.fromJson(habitData);

      // Check if already completed today
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (habit.completedDates.any((d) =>
          d.year == dateOnly.year &&
          d.month == dateOnly.month &&
          d.day == dateOnly.day)) {
        return; // Already completed
      }

      // Add completion date
      final updatedCompletedDates = [...habit.completedDates, dateOnly];

      // Calculate new streak
      final newStreak = _calculateStreak(updatedCompletedDates);
      final newLongestStreak =
          newStreak > habit.longestStreak ? newStreak : habit.longestStreak;

      final updatedHabit = habit.copyWith(
        completedDates: updatedCompletedDates,
        currentStreak: newStreak,
        longestStreak: newLongestStreak,
      );

      final updateData = updatedHabit.toJson();
      updateData.remove('id');

      transaction.update(habitRef, updateData);
    });
  }

  @override
  Future<void> markHabitIncomplete(String habitId, DateTime date) async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final habitRef = _firebaseService.getUserHabits(userId).doc(habitId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final habitSnapshot = await transaction.get(habitRef);
      if (!habitSnapshot.exists) throw Exception('Habit not found');

      final habitData = habitSnapshot.data() as Map<String, dynamic>;
      habitData['id'] = habitSnapshot.id;
      final habit = Habit.fromJson(habitData);

      // Remove completion date
      final dateOnly = DateTime(date.year, date.month, date.day);
      final updatedCompletedDates = habit.completedDates
          .where((d) => !(d.year == dateOnly.year &&
              d.month == dateOnly.month &&
              d.day == dateOnly.day))
          .toList();

      // Recalculate streak
      final newStreak = _calculateStreak(updatedCompletedDates);

      final updatedHabit = habit.copyWith(
        completedDates: updatedCompletedDates,
        currentStreak: newStreak,
      );

      final updateData = updatedHabit.toJson();
      updateData.remove('id');

      transaction.update(habitRef, updateData);
    });
  }

  int _calculateStreak(List<DateTime> completedDates) {
    if (completedDates.isEmpty) return 0;

    // Sort dates in descending order
    final sortedDates = [...completedDates];
    sortedDates.sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    // Check if the most recent completion is today or yesterday
    final mostRecent = sortedDates.first;
    if (!_isSameDay(mostRecent, todayDate) &&
        !_isSameDay(mostRecent, yesterdayDate)) {
      return 0; // Streak broken
    }

    int streak = 0;
    DateTime expectedDate =
        _isSameDay(mostRecent, todayDate) ? todayDate : yesterdayDate;

    for (final date in sortedDates) {
      if (_isSameDay(date, expectedDate)) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else {
        break; // Streak broken
      }
    }

    return streak;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
