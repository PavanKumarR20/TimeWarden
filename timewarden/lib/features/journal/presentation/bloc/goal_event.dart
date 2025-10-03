import 'package:equatable/equatable.dart';
import '../../domain/entities/goal.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();

  @override
  List<Object> get props => [];
}

class GoalLoadRequested extends GoalEvent {
  const GoalLoadRequested();
}

class GoalCreateRequested extends GoalEvent {
  final Goal goal;

  const GoalCreateRequested(this.goal);

  @override
  List<Object> get props => [goal];
}

class GoalUpdateRequested extends GoalEvent {
  final Goal goal;

  const GoalUpdateRequested(this.goal);

  @override
  List<Object> get props => [goal];
}

class GoalDeleteRequested extends GoalEvent {
  final String goalId;

  const GoalDeleteRequested(this.goalId);

  @override
  List<Object> get props => [goalId];
}

class GoalCompletionToggled extends GoalEvent {
  final String goalId;

  const GoalCompletionToggled(this.goalId);

  @override
  List<Object> get props => [goalId];
}

class CompletedGoalsLoadRequested extends GoalEvent {
  const CompletedGoalsLoadRequested();
}

class PendingGoalsLoadRequested extends GoalEvent {
  const PendingGoalsLoadRequested();
}
