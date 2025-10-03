import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../bloc/journal_state.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/goal.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/goal_card.dart';
import '../widgets/journal_search_bar.dart';
import '../widgets/journal_filter_chips.dart';
import '../../../../core/services/haptic_service.dart';
import 'simple_daily_journal_page.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage>
    with TickerProviderStateMixin {
  bool _isSearchVisible = false;
  bool _hasInitialized = false;
  late JournalBloc _journalBloc;
  late GoalBloc _goalBloc;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _journalBloc = context.read<JournalBloc>();
      _goalBloc = context.read<GoalBloc>();
      _journalBloc.add(const JournalLoadRequested());
      _goalBloc.add(const GoalLoadRequested());
      _hasInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal & Goals'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.book),
              text: 'Journal',
            ),
            Tab(
              icon: Icon(Icons.flag),
              text: 'Goals',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              HapticService.buttonTap();
              setState(() {
                _isSearchVisible = !_isSearchVisible;
              });
              if (!_isSearchVisible) {
                _journalBloc.add(const JournalSearchCleared());
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              HapticService.buttonTap();
              switch (value) {
                case 'favorites':
                  _journalBloc.add(const JournalShowFavoritesRequested());
                  break;
                case 'clear_filter':
                  _journalBloc.add(const JournalFilterCleared());
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'favorites',
                child: Row(
                  children: [
                    Icon(Icons.favorite),
                    SizedBox(width: 8),
                    Text('Favorites'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_filter',
                child: Row(
                  children: [
                    Icon(Icons.clear),
                    SizedBox(width: 8),
                    Text('Clear Filter'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Journal Tab
          Column(
            children: [
              if (_isSearchVisible) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: JournalSearchBar(),
                ),
              ],
              const JournalFilterChips(),
              Expanded(
                child: BlocConsumer<JournalBloc, JournalState>(
                  listener: (context, state) {
                    if (state is JournalError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    } else if (state is JournalEntryCreated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Journal entry created successfully!'),
                        ),
                      );
                    } else if (state is JournalEntryUpdated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Journal entry updated successfully!'),
                        ),
                      );
                    } else if (state is JournalEntryDeleted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Journal entry deleted successfully!'),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is JournalLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (state is JournalLoaded) {
                      if (state.entries.isEmpty) {
                        return _buildEmptyState(state);
                      }
                      return _buildJournalList(state.entries);
                    } else if (state is JournalError) {
                      return _buildErrorState(state.message);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
          // Goals Tab
          _buildGoalsTab(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildGoalsTab() {
    return BlocConsumer<GoalBloc, GoalState>(
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
        return Column(
          children: [
            // Goals list
            Expanded(
              child: () {
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
                          Icon(Icons.flag_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No Goals Yet',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
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
                          Icon(Icons.flag_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No Goals Yet',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
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
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
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
                }
                return const SizedBox.shrink();
              }(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        HapticService.buttonTap();
        _showAddDialog();
      },
      heroTag: "journal_fab_${_tabController.index}", // Unique hero tag
      child: Icon(_tabController.index == 0 ? Icons.edit : Icons.add),
    );
  }

  void _showAddDialog() {
    if (_tabController.index == 0) {
      // Journal Entry
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: _journalBloc,
            child: SimpleDailyJournalPage(),
          ),
        ),
      );
    } else {
      // Goal creation
      _showGoalCreationDialog();
    }
  }

  void _showGoalCreationDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? targetDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('Add New Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    hintText: 'Enter your goal...',
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add more details...',
                  ),
                  maxLines: 3,
                  maxLength: 300,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Target Date: '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          dialogSetState(() {
                            targetDate = date;
                          });
                        }
                      },
                      child: Text(
                        targetDate != null
                            ? '${targetDate!.day}/${targetDate!.month}/${targetDate!.year}'
                            : 'Select Date',
                      ),
                    ),
                    if (targetDate != null)
                      IconButton(
                        onPressed: () {
                          dialogSetState(() {
                            targetDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear, size: 18),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  final newGoal = Goal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    createdAt: DateTime.now(),
                    targetEndDate: targetDate,
                    isCompleted: false,
                  );

                  // Create goal via BLoC
                  _goalBloc.add(GoalCreateRequested(newGoal));

                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalList(List<JournalEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: JournalEntryCard(
            entry: entry,
            onTap: () => _navigateToEntry(entry),
            onFavoriteToggle: () => _toggleFavorite(entry),
            onDelete: () => _deleteEntry(entry),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(JournalLoaded state) {
    String message = 'Start your journaling journey!';
    String subtitle = 'Tap the + button to create your first entry.';
    IconData icon = Icons.book_outlined;

    if (state.searchQuery != null) {
      message = 'No entries found';
      subtitle = 'Try a different search term.';
      icon = Icons.search_off;
    } else if (state.currentFilter != null) {
      message = 'No entries with this tag';
      subtitle = 'Try a different filter.';
      icon = Icons.filter_alt_off;
    } else if (state.showingFavorites) {
      message = 'No favorite entries yet';
      subtitle = 'Mark entries as favorites to see them here.';
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              HapticService.buttonTap();
              _journalBloc.add(const JournalLoadRequested());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToEntry(JournalEntry entry) {
    HapticService.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _journalBloc,
          child: SimpleDailyJournalPage(entry: entry),
        ),
      ),
    );
  }

  void _toggleFavorite(JournalEntry entry) {
    _journalBloc.add(
      JournalEntryToggleFavoriteRequested(entry),
    );
  }

  void _deleteEntry(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text(
            'Are you sure you want to delete this journal entry from ${entry.dateString}?'),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.buttonTap();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              HapticService.buttonTap();
              Navigator.of(context).pop();
              _journalBloc.add(
                JournalEntryDeleteRequested(entry.id),
              );
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

  // Goal-related methods

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
      // Goal is already completed, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal is already completed!')),
      );
      return;
    }

    // Mark goal as completed via BLoC
    _goalBloc.add(GoalCompletionToggled(goal.id));
  }

  void _updateGoalStatus(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Goal Status'),
        content: const Text('Mark this goal as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Goal marked as completed! 🎉'),
                ),
              );
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
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

              // Delete goal via BLoC
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
}
