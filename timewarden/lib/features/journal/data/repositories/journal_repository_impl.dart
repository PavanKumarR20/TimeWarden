import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/log_service.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';

class JournalRepositoryImpl implements JournalRepository {
  final FirebaseService _firebaseService;
  static const String _collection = 'journal_entries';

  JournalRepositoryImpl(this._firebaseService);

  CollectionReference get _entriesCollection {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firebaseService.firestore
        .collection('users')
        .doc(userId)
        .collection(_collection);
  }

  @override
  Future<List<JournalEntry>> getEntries() async {
    try {
      LogService.journal(
          'Getting journal entries for user: ${_firebaseService.currentUser?.uid}');

      final querySnapshot =
          await _entriesCollection.orderBy('createdAt', descending: true).get();

      LogService.journal(
          'Retrieved ${querySnapshot.docs.length} journal entries');

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return JournalEntry.fromJson(data);
      }).toList();
    } catch (e) {
      LogService.journal('Error getting journal entries', error: e);
      throw Exception('Failed to get journal entries: $e');
    }
  }

  @override
  Future<JournalEntry?> getEntryById(String id) async {
    try {
      LogService.journal('Getting journal entry with ID: $id');

      final doc = await _entriesCollection.doc(id).get();

      if (!doc.exists) {
        LogService.journal('Journal entry not found with ID: $id');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      LogService.journal('Retrieved journal entry: ${data['title']}');
      return JournalEntry.fromJson(data);
    } catch (e) {
      LogService.journal('Error getting journal entry', error: e);
      throw Exception('Failed to get journal entry: $e');
    }
  }

  @override
  Future<List<JournalEntry>> getEntriesByDateRange(
      DateTime start, DateTime end) async {
    try {
      LogService.journal('Getting journal entries from $start to $end');

      final querySnapshot = await _entriesCollection
          .where('createdAt', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('createdAt', descending: true)
          .get();

      LogService.journal(
          'Retrieved ${querySnapshot.docs.length} journal entries in date range');

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return JournalEntry.fromJson(data);
      }).toList();
    } catch (e) {
      LogService.journal('Error getting journal entries by date range',
          error: e);
      throw Exception('Failed to get journal entries by date range: $e');
    }
  }

  @override
  Future<List<JournalEntry>> getEntriesByTag(String tag) async {
    try {
      LogService.journal('Getting journal entries with tag: $tag');

      final querySnapshot = await _entriesCollection
          .where('tags', arrayContains: tag)
          .orderBy('createdAt', descending: true)
          .get();

      LogService.journal(
          'Retrieved ${querySnapshot.docs.length} journal entries with tag: $tag');

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return JournalEntry.fromJson(data);
      }).toList();
    } catch (e) {
      LogService.journal('Error getting journal entries by tag', error: e);
      throw Exception('Failed to get journal entries by tag: $e');
    }
  }

  @override
  Future<List<JournalEntry>> getFavoriteEntries() async {
    try {
      LogService.journal('Getting favorite journal entries');

      final querySnapshot = await _entriesCollection
          .where('isFavorite', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      LogService.journal(
          'Retrieved ${querySnapshot.docs.length} favorite journal entries');

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return JournalEntry.fromJson(data);
      }).toList();
    } catch (e) {
      LogService.journal('Error getting favorite journal entries', error: e);
      throw Exception('Failed to get favorite journal entries: $e');
    }
  }

  @override
  Future<List<JournalEntry>> searchEntries(String query) async {
    try {
      LogService.journal('Searching journal entries for: $query');

      // Note: Firestore doesn't support full-text search, so we'll get all entries
      // and filter client-side. For production, consider using Algolia or similar.
      final querySnapshot =
          await _entriesCollection.orderBy('createdAt', descending: true).get();

      final allEntries = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return JournalEntry.fromJson(data);
      }).toList();

      final searchResults = allEntries.where((entry) {
        final searchTerm = query.toLowerCase();
        return entry.title.toLowerCase().contains(searchTerm) ||
            entry.content.toLowerCase().contains(searchTerm) ||
            entry.tags.any((tag) => tag.toLowerCase().contains(searchTerm));
      }).toList();

      LogService.journal(
          'Found ${searchResults.length} journal entries matching: $query');
      return searchResults;
    } catch (e) {
      LogService.journal('Error searching journal entries', error: e);
      throw Exception('Failed to search journal entries: $e');
    }
  }

  @override
  Future<void> createEntry(JournalEntry entry) async {
    try {
      LogService.journal('Creating journal entry: ${entry.title}');

      final data = entry.toJson();
      data.remove('id'); // Remove ID as Firestore will generate it

      await _entriesCollection.add(data);

      LogService.journal('Journal entry created successfully: ${entry.title}');
    } catch (e) {
      LogService.journal('Error creating journal entry', error: e);
      throw Exception('Failed to create journal entry: $e');
    }
  }

  @override
  Future<void> updateEntry(JournalEntry entry) async {
    try {
      LogService.journal('Updating journal entry: ${entry.title}');

      final data = entry.toJson();
      data.remove('id'); // Remove ID from data

      await _entriesCollection.doc(entry.id).update(data);

      LogService.journal('Journal entry updated successfully: ${entry.title}');
    } catch (e) {
      LogService.journal('Error updating journal entry', error: e);
      throw Exception('Failed to update journal entry: $e');
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    try {
      LogService.journal('Deleting journal entry with ID: $id');

      await _entriesCollection.doc(id).delete();

      LogService.journal('Journal entry deleted successfully: $id');
    } catch (e) {
      LogService.journal('Error deleting journal entry', error: e);
      throw Exception('Failed to delete journal entry: $e');
    }
  }

  @override
  Future<List<String>> getAllTags() async {
    try {
      LogService.journal('Getting all journal tags');

      final querySnapshot = await _entriesCollection.get();

      final Set<String> allTags = {};
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final tags = List<String>.from(data['tags'] as List? ?? []);
        allTags.addAll(tags);
      }

      final tagList = allTags.toList()..sort();
      LogService.journal('Retrieved ${tagList.length} unique tags');

      return tagList;
    } catch (e) {
      LogService.journal('Error getting all tags', error: e);
      throw Exception('Failed to get all tags: $e');
    }
  }
}
