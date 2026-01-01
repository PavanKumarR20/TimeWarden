import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/habits/domain/entities/habit.dart';
import '../../features/habits/presentation/bloc/habits_bloc.dart';
import '../../features/dashboard/domain/entities/user_stats.dart';
import '../../features/dashboard/data/repositories/user_stats_repository_impl.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../services/points_service.dart';

class PointsDetailDialog extends StatefulWidget {
  const PointsDetailDialog({super.key});

  @override
  State<PointsDetailDialog> createState() => _PointsDetailDialogState();
}

class _PointsDetailDialogState extends State<PointsDetailDialog> {
  final _descriptionController = TextEditingController();
  bool _isEditingDescription = false;
  UserStats? _userStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    final userId = FirebaseService().currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final statsRepo = UserStatsRepositoryImpl(FirebaseService());
    final stats = await statsRepo.getUserStats(userId);

    if (mounted) {
      setState(() {
        _userStats = stats;
        _isLoading = false;
        if (stats != null) {
          _descriptionController.text = stats.pointRewardDescription ?? '';
        }
      });
    }
  }

  void _adjustPoints(double delta) async {
    HapticService.selectionClick();

    // Update local state immediately for instant feedback
    if (_userStats != null) {
      final newTotal = PointsService.manualAdjustPoints(
        userStats: _userStats!,
        delta: delta,
      );

      setState(() {
        _userStats = _userStats!.copyWith(totalPointsToday: newTotal);
      });
    }

    // Dispatch event to update backend
    context.read<HabitsBloc>().add(PointsManuallyAdjusted(delta));
  }

  void _saveDescription() {
    HapticService.buttonTap();
    context.read<HabitsBloc>().add(
          PointRewardDescriptionUpdated(_descriptionController.text.trim()),
        );
    setState(() => _isEditingDescription = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reward description saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    if (_userStats == null) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading points data',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again later',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    return BlocBuilder<HabitsBloc, HabitsState>(
      builder: (context, state) {
        final habits = state is HabitsLoaded ? state.habits : <Habit>[];
        final isUnlimited = PointsService.isUnlimitedMode(habits: habits);
        final pointsDisplay = PointsService.getPointsDisplayText(
          points: _userStats!.totalPointsToday,
          isUnlimited: isUnlimited,
        );

        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 24),
                _buildPointsDisplay(theme, pointsDisplay, isUnlimited),
                const SizedBox(height: 24),
                if (!isUnlimited) ...[
                  _buildManualAdjustmentControls(theme),
                  const SizedBox(height: 24),
                ],
                _buildRewardDescription(theme, _userStats!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.stars,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Today\'s Points',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            HapticService.buttonTap();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildPointsDisplay(
      ThemeData theme, String pointsDisplay, bool isUnlimited) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            pointsDisplay,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUnlimited ? 'All habits completed!' : 'Points earned today',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualAdjustmentControls(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manual Adjustment',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAdjustButton(context, '-2', -2.0),
            _buildAdjustButton(context, '-1', -1.0),
            _buildAdjustButton(context, '-0.5', -0.5),
            _buildAdjustButton(context, '+0.5', 0.5),
            _buildAdjustButton(context, '+1', 1.0),
            _buildAdjustButton(context, '+2', 2.0),
          ],
        ),
      ],
    );
  }

  Widget _buildRewardDescription(ThemeData theme, UserStats userStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reward per Point',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_isEditingDescription)
          Column(
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'e.g., 15 min free time, 1 game',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.card_giftcard),
                ),
                maxLines: 2,
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      HapticService.buttonTap();
                      setState(() {
                        _isEditingDescription = false;
                        _descriptionController.text =
                            userStats.pointRewardDescription ?? '';
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saveDescription,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          )
        else
          InkWell(
            onTap: () {
              HapticService.buttonTap();
              setState(() => _isEditingDescription = true);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userStats.pointRewardDescription?.isEmpty ?? true
                          ? 'Tap to set reward description'
                          : userStats.pointRewardDescription!,
                      style: TextStyle(
                        color: userStats.pointRewardDescription?.isEmpty ?? true
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdjustButton(BuildContext context, String label, double delta) {
    final isNegative = delta < 0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          onPressed: () => _adjustPoints(delta),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(
              color: isNegative
                  ? Colors.red.withOpacity(0.5)
                  : Colors.green.withOpacity(0.5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isNegative ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
