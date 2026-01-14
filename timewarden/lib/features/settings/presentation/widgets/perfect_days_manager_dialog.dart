import 'package:flutter/material.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../dashboard/domain/entities/user_stats.dart';
import '../../../dashboard/data/repositories/user_stats_repository_impl.dart';

class PerfectDaysManagerDialog extends StatefulWidget {
  const PerfectDaysManagerDialog({super.key});

  @override
  State<PerfectDaysManagerDialog> createState() =>
      _PerfectDaysManagerDialogState();
}

class _PerfectDaysManagerDialogState extends State<PerfectDaysManagerDialog> {
  late UserStatsRepositoryImpl _statsRepository;
  UserStats? _userStats;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _statsRepository = UserStatsRepositoryImpl(FirebaseService());
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseService().currentUserId;
      if (userId != null) {
        final stats = await _statsRepository.getUserStats(userId);
        setState(() {
          _userStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load stats: $e');
    }
  }

  Future<void> _incrementPerfectDays() async {
    final userId = FirebaseService().currentUserId;
    if (userId == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _statsRepository.incrementPerfectDays(userId);
      await _loadUserStats(); // Refresh stats
      HapticService.buttonTap();
      _showSuccess('Perfect days incremented!');
    } catch (e) {
      _showError('Failed to increment: $e');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _decrementPerfectDays() async {
    final userId = FirebaseService().currentUserId;
    if (userId == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _statsRepository.decrementPerfectDays(userId);
      await _loadUserStats(); // Refresh stats
      HapticService.buttonTap();
      _showSuccess('Perfect days decremented!');
    } catch (e) {
      _showError('Failed to decrement: $e');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _testCreateInitialStats() async {
    final userId = FirebaseService().currentUserId;
    if (userId == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Get existing stats or create new ones
      final existingStats = await _statsRepository.getUserStats(userId);
      final now = DateTime.now();

      if (existingStats == null) {
        // Only create if doesn't exist
        final stats = UserStats(
          userId: userId,
          perfectDays: 0,
          lastUpdated: now,
          createdAt: now,
        );
        await _statsRepository.saveUserStats(stats);
        _showSuccess('Initial stats created!');
      } else {
        _showError('Stats already exist! Use other buttons to modify.');
      }
      await _loadUserStats();
    } catch (e) {
      _showError('Failed to create initial stats: $e');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.orange),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Perfect Days Manager',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                Text(
                  'Current Perfect Days',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${_userStats?.perfectDays ?? 0}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Manual Controls',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ElevatedButton.icon(
                          onPressed: _isUpdating ? null : _decrementPerfectDays,
                          icon: const Icon(Icons.remove, size: 18),
                          label: const Text(
                            'Decrease',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ElevatedButton.icon(
                          onPressed: _isUpdating ? null : _incrementPerfectDays,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Increase',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isUpdating)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: _loadUserStats,
          child: const Text('Refresh'),
        ),
      ],
    );
  }
}
