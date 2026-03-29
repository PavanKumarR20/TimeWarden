import 'package:equatable/equatable.dart';
import '../../domain/entities/goal.dart';

abstract class GoalState extends Equatable {
  const GoalState();

  @override
  List<Object> get props => [];
}

class GoalInitial extends GoalState {}

class GoalLoading extends GoalState {}

class GoalLoaded extends GoalState {
  final List<Goal> goals;

  const GoalLoaded(this.goals);

  @override
  List<Object> get props => [goals];
}

class GoalOperationSuccess extends GoalState {
  final String message;
  final List<Goal> goals;

  const GoalOperationSuccess({
    required this.message,
    required this.goals,
  });

  @override
  List<Object> get props => [message, goals];
}

class GoalError extends GoalState {
  final String message;

  const GoalError(this.message);

  @override
  List<Object> get props => [message];
}
