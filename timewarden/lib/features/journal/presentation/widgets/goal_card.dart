import 'package:flutter/material.dart';
import '../../domain/entities/goal.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (goal.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            goal.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCompletionChip(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (goal.targetEndDate != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: goal.isOverdue ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      goal.targetDateString ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: goal.isOverdue ? Colors.red : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    goal.dateString,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  _buildActionButtons(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (goal.isCompleted ? Colors.green : Colors.grey).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            goal.isCompleted ? '✅' : '⚪',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            goal.isCompleted ? 'Completed' : 'Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: goal.isCompleted ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onComplete != null && !goal.isCompleted) ...[
          InkWell(
            onTap: onComplete,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        if (onDelete != null)
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
}
