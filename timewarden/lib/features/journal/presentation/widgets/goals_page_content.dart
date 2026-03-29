import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../../domain/entities/goal.dart';
import '../widgets/goal_card.dart';
import '../../../../core/services/haptic_service.dart';

class GoalsPageContent extends StatefulWidget {
  const GoalsPageContent({super.key});

  @override
  State<GoalsPageContent> createState() => _GoalsPageContentState();
}

class _GoalsPageContentState extends State<GoalsPageContent> {
  late GoalBloc _goalBloc;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _goalBloc = context.read<GoalBloc>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      _goalBloc.add(const GoalLoadRequested());
      _hasInitialized = true;
    }
  }

  void _showGoalDetails(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.flag, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Status: ${goal.isCompleted ? 'Completed' : 'Pending'}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Target: ${goal.targetDateString ?? 'No deadline'}'),
              ],
            ),
            if (goal.targetEndDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('Due: ${goal.targetDateString}'),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleGoalCompletion(Goal goal) {
    if (goal.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal is already completed!')),
      );
      return;
    }

    _goalBloc.add(GoalCompletionToggled(goal.id));
  }

  void _deleteGoal(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _goalBloc.add(GoalDeleteRequested(goal.id));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createNewGoal() async {
    await HapticService.lightImpact();

    // Navigate to goal creation page (you'll need to implement this)
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Goal'),
        content: const Text('Goal creation dialog would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      body: BlocConsumer<GoalBloc, GoalState>(
        listener: (context, state) {
          if (state is GoalOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
              ),
            );
          } else if (state is GoalError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is GoalLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is GoalLoaded) {
            if (state.goals.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No Goals Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap + to create your first goal',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.goals.length,
              itemBuilder: (context, index) {
                final goal = state.goals[index];
                return GoalCard(
                  goal: goal,
                  onTap: () => _showGoalDetails(goal),
                  onComplete: () => _toggleGoalCompletion(goal),
                  onDelete: () => _deleteGoal(goal),
                );
              },
            );
          } else if (state is GoalOperationSuccess) {
            if (state.goals.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No Goals Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap + to create your first goal',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.goals.length,
              itemBuilder: (context, index) {
                final goal = state.goals[index];
                return GoalCard(
                  goal: goal,
                  onTap: () => _showGoalDetails(goal),
                  onComplete: () => _toggleGoalCompletion(goal),
                  onDelete: () => _deleteGoal(goal),
                );
              },
            );
          } else if (state is GoalError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading goals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _goalBloc.add(const GoalLoadRequested());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Goals Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create your first goal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewGoal,
        heroTag: "goals_fab",
        child: const Icon(Icons.add),
      ),
    );
  }
}
