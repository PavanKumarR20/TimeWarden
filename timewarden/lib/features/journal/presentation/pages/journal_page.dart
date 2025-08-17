import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../bloc/journal_state.dart';
import '../../domain/entities/journal_entry.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/journal_search_bar.dart';
import '../widgets/journal_filter_chips.dart';
import '../../../../core/services/haptic_service.dart';
import 'add_edit_journal_entry_page.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  bool _isSearchVisible = false;
  bool _hasInitialized = false;
  late JournalBloc _journalBloc;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _journalBloc = context.read<JournalBloc>();
      _journalBloc.add(const JournalLoadRequested());
      _hasInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        centerTitle: true,
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
      body: Column(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticService.buttonTap();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: _journalBloc,
                child: AddEditJournalEntryPage(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
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
          child: AddEditJournalEntryPage(entry: entry),
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
        content: Text('Are you sure you want to delete "${entry.title}"?'),
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
}
