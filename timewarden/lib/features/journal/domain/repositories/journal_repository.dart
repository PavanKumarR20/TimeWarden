import '../entities/journal_entry.dart';

abstract class JournalRepository {
  Future<List<JournalEntry>> getEntries();
  Future<JournalEntry?> getEntryById(String id);
  Future<List<JournalEntry>> getEntriesByDateRange(
      DateTime start, DateTime end);
  Future<List<JournalEntry>> getEntriesByTag(String tag);
  Future<List<JournalEntry>> getFavoriteEntries();
  Future<List<JournalEntry>> searchEntries(String query);
  Future<void> createEntry(JournalEntry entry);
  Future<void> updateEntry(JournalEntry entry);
  Future<void> deleteEntry(String id);
  Future<List<String>> getAllTags();
}
