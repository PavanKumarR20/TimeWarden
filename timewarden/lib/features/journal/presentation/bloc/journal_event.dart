import 'package:equatable/equatable.dart';
import '../../domain/entities/journal_entry.dart';

abstract class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object?> get props => [];
}

class JournalLoadRequested extends JournalEvent {
  const JournalLoadRequested();
}

class JournalEntryCreateRequested extends JournalEvent {
  final JournalEntry entry;

  const JournalEntryCreateRequested(this.entry);

  @override
  List<Object> get props => [entry];
}

class JournalEntryUpdateRequested extends JournalEvent {
  final JournalEntry entry;

  const JournalEntryUpdateRequested(this.entry);

  @override
  List<Object> get props => [entry];
}

class JournalEntryDeleteRequested extends JournalEvent {
  final String entryId;

  const JournalEntryDeleteRequested(this.entryId);

  @override
  List<Object> get props => [entryId];
}

class JournalEntryToggleFavoriteRequested extends JournalEvent {
  final JournalEntry entry;

  const JournalEntryToggleFavoriteRequested(this.entry);

  @override
  List<Object> get props => [entry];
}

class JournalSearchRequested extends JournalEvent {
  final String query;

  const JournalSearchRequested(this.query);

  @override
  List<Object> get props => [query];
}

class JournalSearchCleared extends JournalEvent {
  const JournalSearchCleared();
}

class JournalFilterByTagRequested extends JournalEvent {
  final String tag;

  const JournalFilterByTagRequested(this.tag);

  @override
  List<Object> get props => [tag];
}

class JournalFilterCleared extends JournalEvent {
  const JournalFilterCleared();
}

class JournalShowFavoritesRequested extends JournalEvent {
  const JournalShowFavoritesRequested();
}

class JournalTagsLoadRequested extends JournalEvent {
  const JournalTagsLoadRequested();
}
