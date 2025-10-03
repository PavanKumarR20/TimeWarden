import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/log_service.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  final FirebaseService _firebaseService;
  static const String _collection = 'goals';

  GoalRepositoryImpl(this._firebaseService);

  CollectionReference get _goalsCollection {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firebaseService.firestore
        .collection('users')
        .doc(userId)
        .collection(_collection);
  }

  @override
  Future<List<Goal>> getGoals() async {
    try {
      LogService.info(
          'Getting goals for user: ${_firebaseService.currentUser?.uid}');

      final querySnapshot =
          await _goalsCollection.orderBy('createdAt', descending: true).get();

      LogService.info('Retrieved ${querySnapshot.docs.length} goals');

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Goal.fromJson(data);
      }).toList();
    } catch (e) {
      LogService.error('Error getting goals', error: e);
      throw Exception('Failed to get goals: $e');
    }
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    try {
      LogService.info('Getting goal by ID: $id');

      final doc = await _goalsCollection.doc(id).get();

      if (!doc.exists) {
        LogService.info('Goal not found: $id');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Goal.fromJson(data);
    } catch (e) {
      LogService.error('Error getting goal by ID', error: e);
      throw Exception('Failed to get goal: $e');
    }
  }

  @override
  Future<void> createGoal(Goal goal) async {
    try {
      LogService.info('Creating goal: ${goal.title}');

      final data = goal.toJson();
      data.remove('id'); // Remove ID as Firestore will generate it

      await _goalsCollection.add(data);
      LogService.info('Goal created successfully: ${goal.title}');
    } catch (e) {
      LogService.error('Error creating goal', error: e);
      throw Exception('Failed to create goal: $e');
    }
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    try {
      LogService.info('Updating goal: ${goal.id}');

      final data = goal.toJson();
      data.remove('id'); // Remove ID before updating

      await _goalsCollection.doc(goal.id).update(data);
      LogService.info('Goal updated successfully: ${goal.id}');
    } catch (e) {
      LogService.error('Error updating goal', error: e);
      throw Exception('Failed to update goal: $e');
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      LogService.info('Deleting goal: $id');

      await _goalsCollection.doc(id).delete();
      LogService.info('Goal deleted successfully: $id');
    } catch (e) {
      LogService.error('Error deleting goal', error: e);
      throw Exception('Failed to delete goal: $e');
    }
  }

  @override
  Future<void> toggleGoalCompletion(String id) async {
    try {
      LogService.info('Toggling goal completion: $id');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final goalRef = _goalsCollection.doc(id);
        final goalDoc = await transaction.get(goalRef);

        if (!goalDoc.exists) {
          throw Exception('Goal not found');
        }

        final data = goalDoc.data() as Map<String, dynamic>;
        final isCompleted = data['isCompleted'] as bool? ?? false;
        final now = DateTime.now();

        transaction.update(goalRef, {
          'isCompleted': !isCompleted,
          'actualEndDate': !isCompleted ? now.toIso8601String() : null,
        });
      });

      LogService.info('Goal completion toggled successfully: $id');
    } catch (e) {
      LogService.error('Error toggling goal completion', error: e);
      throw Exception('Failed to toggle goal completion: $e');
    }
  }

  @override
  Future<List<Goal>> getCompletedGoals() async {
    try {
      LogService.info('Getting completed goals');

      final querySnapshot = await _goalsCollection
          .where('isCompleted', isEqualTo: true)
          .orderBy('actualEndDate', descending: true)
          .get();

      LogService.info('Retrieved ${querySnapshot.docs.length} completed goals');

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Goal.fromJson(data);
      }).toList();
    } catch (e) {
      LogService.error('Error getting completed goals', error: e);
      throw Exception('Failed to get completed goals: $e');
    }
  }

  @override
  Future<List<Goal>> getPendingGoals() async {
    try {
      LogService.info('Getting pending goals');

      final querySnapshot = await _goalsCollection
          .where('isCompleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      LogService.info('Retrieved ${querySnapshot.docs.length} pending goals');

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Goal.fromJson(data);
      }).toList();
    } catch (e) {
      LogService.error('Error getting pending goals', error: e);
      throw Exception('Failed to get pending goals: $e');
    }
  }
}
