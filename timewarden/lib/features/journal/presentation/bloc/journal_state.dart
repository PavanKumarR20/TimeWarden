import 'package:equatable/equatable.dart';
import '../../domain/entities/journal_entry.dart';

abstract class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

class JournalInitial extends JournalState {
  const JournalInitial();
}

class JournalLoading extends JournalState {
  const JournalLoading();
}

class JournalLoaded extends JournalState {
  final List<JournalEntry> entries;
  final List<String> availableTags;
  final String? currentFilter;
  final String? searchQuery;
  final bool showingFavorites;

  const JournalLoaded({
    required this.entries,
    this.availableTags = const [],
    this.currentFilter,
    this.searchQuery,
    this.showingFavorites = false,
  });

  JournalLoaded copyWith({
    List<JournalEntry>? entries,
    List<String>? availableTags,
    String? currentFilter,
    String? searchQuery,
    bool? showingFavorites,
  }) {
    return JournalLoaded(
      entries: entries ?? this.entries,
      availableTags: availableTags ?? this.availableTags,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      showingFavorites: showingFavorites ?? this.showingFavorites,
    );
  }

  @override
  List<Object?> get props => [
        entries,
        availableTags,
        currentFilter,
        searchQuery,
        showingFavorites,
      ];
}

class JournalError extends JournalState {
  final String message;

  const JournalError(this.message);

  @override
  List<Object> get props => [message];
}

class JournalEntryCreating extends JournalState {
  const JournalEntryCreating();
}

class JournalEntryCreated extends JournalState {
  final JournalEntry entry;

  const JournalEntryCreated(this.entry);

  @override
  List<Object> get props => [entry];
}

class JournalEntryUpdating extends JournalState {
  const JournalEntryUpdating();
}

class JournalEntryUpdated extends JournalState {
  final JournalEntry entry;

  const JournalEntryUpdated(this.entry);

  @override
  List<Object> get props => [entry];
}

class JournalEntryDeleting extends JournalState {
  const JournalEntryDeleting();
}

class JournalEntryDeleted extends JournalState {
  final String entryId;

  const JournalEntryDeleted(this.entryId);

  @override
  List<Object> get props => [entryId];
}
