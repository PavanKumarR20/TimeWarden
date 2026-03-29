import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/log_service.dart';
import '../../domain/repositories/goal_repository.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final GoalRepository _goalRepository;

  GoalBloc(this._goalRepository) : super(GoalInitial()) {
    on<GoalLoadRequested>(_onGoalLoadRequested);
    on<GoalCreateRequested>(_onGoalCreateRequested);
    on<GoalUpdateRequested>(_onGoalUpdateRequested);
    on<GoalDeleteRequested>(_onGoalDeleteRequested);
    on<GoalCompletionToggled>(_onGoalCompletionToggled);
    on<CompletedGoalsLoadRequested>(_onCompletedGoalsLoadRequested);
    on<PendingGoalsLoadRequested>(_onPendingGoalsLoadRequested);
  }

  Future<void> _onGoalLoadRequested(
    GoalLoadRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      emit(GoalLoading());
      LogService.info('Loading goals...');

      final goals = await _goalRepository.getGoals();

      LogService.info('Loaded ${goals.length} goals');
      emit(GoalLoaded(goals));
    } catch (e) {
      LogService.error('Error loading goals', error: e);
      emit(GoalError('Failed to load goals: ${e.toString()}'));
    }
  }

  Future<void> _onGoalCreateRequested(
    GoalCreateRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      LogService.info('Creating goal: ${event.goal.title}');

      await _goalRepository.createGoal(event.goal);

      // Reload goals after creation
      final goals = await _goalRepository.getGoals();

      LogService.info('Goal created successfully');
      emit(GoalOperationSuccess(
        message: 'Goal created successfully!',
        goals: goals,
      ));
    } catch (e) {
      LogService.error('Error creating goal', error: e);
      emit(GoalError('Failed to create goal: ${e.toString()}'));
    }
  }

  Future<void> _onGoalUpdateRequested(
    GoalUpdateRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      LogService.info('Updating goal: ${event.goal.id}');

      await _goalRepository.updateGoal(event.goal);

      // Reload goals after update
      final goals = await _goalRepository.getGoals();

      LogService.info('Goal updated successfully');
      emit(GoalOperationSuccess(
        message: 'Goal updated successfully!',
        goals: goals,
      ));
    } catch (e) {
      LogService.error('Error updating goal', error: e);
      emit(GoalError('Failed to update goal: ${e.toString()}'));
    }
  }

  Future<void> _onGoalDeleteRequested(
    GoalDeleteRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      LogService.info('Deleting goal: ${event.goalId}');

      await _goalRepository.deleteGoal(event.goalId);

      // Reload goals after deletion
      final goals = await _goalRepository.getGoals();

      LogService.info('Goal deleted successfully');
      emit(GoalOperationSuccess(
        message: 'Goal deleted successfully!',
        goals: goals,
      ));
    } catch (e) {
      LogService.error('Error deleting goal', error: e);
      emit(GoalError('Failed to delete goal: ${e.toString()}'));
    }
  }

  Future<void> _onGoalCompletionToggled(
    GoalCompletionToggled event,
    Emitter<GoalState> emit,
  ) async {
    try {
      LogService.info('Toggling goal completion: ${event.goalId}');

      await _goalRepository.toggleGoalCompletion(event.goalId);

      // Reload goals after toggling completion
      final goals = await _goalRepository.getGoals();

      LogService.info('Goal completion toggled successfully');
      emit(GoalOperationSuccess(
        message: 'Goal updated successfully!',
        goals: goals,
      ));
    } catch (e) {
      LogService.error('Error toggling goal completion', error: e);
      emit(GoalError('Failed to update goal: ${e.toString()}'));
    }
  }

  Future<void> _onCompletedGoalsLoadRequested(
    CompletedGoalsLoadRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      emit(GoalLoading());
      LogService.info('Loading completed goals...');

      final goals = await _goalRepository.getCompletedGoals();

      LogService.info('Loaded ${goals.length} completed goals');
      emit(GoalLoaded(goals));
    } catch (e) {
      LogService.error('Error loading completed goals', error: e);
      emit(GoalError('Failed to load completed goals: ${e.toString()}'));
    }
  }

  Future<void> _onPendingGoalsLoadRequested(
    PendingGoalsLoadRequested event,
    Emitter<GoalState> emit,
  ) async {
    try {
      emit(GoalLoading());
      LogService.info('Loading pending goals...');

      final goals = await _goalRepository.getPendingGoals();

      LogService.info('Loaded ${goals.length} pending goals');
      emit(GoalLoaded(goals));
    } catch (e) {
      LogService.error('Error loading pending goals', error: e);
      emit(GoalError('Failed to load pending goals: ${e.toString()}'));
    }
  }
}
