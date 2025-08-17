import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/journal_repository.dart';
import '../../../../core/services/haptic_service.dart';
import 'journal_event.dart';
import 'journal_state.dart';

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final JournalRepository _repository;

  JournalBloc(this._repository) : super(const JournalInitial()) {
    on<JournalLoadRequested>(_onLoadRequested);
    on<JournalEntryCreateRequested>(_onEntryCreateRequested);
    on<JournalEntryUpdateRequested>(_onEntryUpdateRequested);
    on<JournalEntryDeleteRequested>(_onEntryDeleteRequested);
    on<JournalEntryToggleFavoriteRequested>(_onEntryToggleFavoriteRequested);
    on<JournalSearchRequested>(_onSearchRequested);
    on<JournalSearchCleared>(_onSearchCleared);
    on<JournalFilterByTagRequested>(_onFilterByTagRequested);
    on<JournalFilterCleared>(_onFilterCleared);
    on<JournalShowFavoritesRequested>(_onShowFavoritesRequested);
    on<JournalTagsLoadRequested>(_onTagsLoadRequested);
  }

  Future<void> _onLoadRequested(
    JournalLoadRequested event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalLoading());

    try {
      // Load entries and tags using API calls
      final entries = await _repository.getEntries();
      final tags = await _repository.getAllTags();

      emit(JournalLoaded(
        entries: entries,
        availableTags: tags,
      ));
    } catch (e) {
      emit(JournalError('Failed to load journal entries: $e'));
    }
  }

  Future<void> _onEntryCreateRequested(
    JournalEntryCreateRequested event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalEntryCreating());

    try {
      await _repository.createEntry(event.entry);
      HapticService.successAction();
      emit(JournalEntryCreated(event.entry));

      // Reload entries to show the new entry
      add(const JournalLoadRequested());
    } catch (e) {
      HapticService.errorAction();
      emit(JournalError('Failed to create journal entry: $e'));
    }
  }

  Future<void> _onEntryUpdateRequested(
    JournalEntryUpdateRequested event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalEntryUpdating());

    try {
      await _repository.updateEntry(event.entry);
      HapticService.successAction();
      emit(JournalEntryUpdated(event.entry));

      // Reload entries to show the updated entry
      add(const JournalLoadRequested());
    } catch (e) {
      HapticService.errorAction();
      emit(JournalError('Failed to update journal entry: $e'));
    }
  }

  Future<void> _onEntryDeleteRequested(
    JournalEntryDeleteRequested event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalEntryDeleting());

    try {
      await _repository.deleteEntry(event.entryId);
      HapticService.successAction();
      emit(JournalEntryDeleted(event.entryId));

      // Reload entries to remove the deleted entry
      add(const JournalLoadRequested());
    } catch (e) {
      HapticService.errorAction();
      emit(JournalError('Failed to delete journal entry: $e'));
    }
  }

  Future<void> _onEntryToggleFavoriteRequested(
    JournalEntryToggleFavoriteRequested event,
    Emitter<JournalState> emit,
  ) async {
    try {
      final updatedEntry = event.entry.copyWith(
        isFavorite: !event.entry.isFavorite,
        updatedAt: DateTime.now(),
      );

      await _repository.updateEntry(updatedEntry);
      HapticService.lightImpact();

      // Reload entries to show the updated favorite status
      add(const JournalLoadRequested());
    } catch (e) {
      HapticService.errorAction();
      emit(JournalError('Failed to toggle favorite: $e'));
    }
  }

  Future<void> _onSearchRequested(
    JournalSearchRequested event,
    Emitter<JournalState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JournalLoaded) return;

    emit(const JournalLoading());

    try {
      final searchResults = await _repository.searchEntries(event.query);
      emit(currentState.copyWith(
        entries: searchResults,
        searchQuery: event.query,
        currentFilter: null,
        showingFavorites: false,
      ));
    } catch (e) {
      emit(JournalError('Failed to search entries: $e'));
    }
  }

  Future<void> _onSearchCleared(
    JournalSearchCleared event,
    Emitter<JournalState> emit,
  ) async {
    add(const JournalLoadRequested());
  }

  Future<void> _onFilterByTagRequested(
    JournalFilterByTagRequested event,
    Emitter<JournalState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JournalLoaded) return;

    emit(const JournalLoading());

    try {
      final filteredEntries = await _repository.getEntriesByTag(event.tag);
      emit(currentState.copyWith(
        entries: filteredEntries,
        currentFilter: event.tag,
        searchQuery: null,
        showingFavorites: false,
      ));
    } catch (e) {
      emit(JournalError('Failed to filter by tag: $e'));
    }
  }

  Future<void> _onFilterCleared(
    JournalFilterCleared event,
    Emitter<JournalState> emit,
  ) async {
    add(const JournalLoadRequested());
  }

  Future<void> _onShowFavoritesRequested(
    JournalShowFavoritesRequested event,
    Emitter<JournalState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JournalLoaded) return;

    emit(const JournalLoading());

    try {
      final favoriteEntries = await _repository.getFavoriteEntries();
      emit(currentState.copyWith(
        entries: favoriteEntries,
        showingFavorites: true,
        currentFilter: null,
        searchQuery: null,
      ));
    } catch (e) {
      emit(JournalError('Failed to load favorite entries: $e'));
    }
  }

  Future<void> _onTagsLoadRequested(
    JournalTagsLoadRequested event,
    Emitter<JournalState> emit,
  ) async {
    try {
      final tags = await _repository.getAllTags();
      final currentState = state;
      if (currentState is JournalLoaded) {
        emit(currentState.copyWith(availableTags: tags));
      }
    } catch (e) {
      // Don't emit error for tags loading failure, just continue
    }
  }
}
