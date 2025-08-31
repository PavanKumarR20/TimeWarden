import 'package:shared_preferences/shared_preferences.dart';
import '../log_service.dart';

class SecurityService {
  static const String _journalLockEnabledKey = 'journal_locked';
  static const String _journalPinKey = 'journal_pin';
  static const String _journalUnlockedKey = 'journal_unlocked_timestamp';

  // Auto-lock after 5 minutes of inactivity
  static const Duration _autoLockDuration = Duration(minutes: 5);

  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();
  SecurityService._();

  // Check if journal lock is enabled
  Future<bool> isJournalLockEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_journalLockEnabledKey) ?? false;
    } catch (e) {
      LogService.warning('Error checking journal lock status',
          tag: 'SecurityService', error: e);
      return false;
    }
  }

  // Enable journal lock with PIN
  Future<bool> enableJournalLock(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_journalPinKey, pin);
      await prefs.setBool(_journalLockEnabledKey, true);
      LogService.info('Journal lock enabled successfully',
          tag: 'SecurityService');
      return true;
    } catch (e) {
      LogService.error('Error enabling journal lock',
          tag: 'SecurityService', error: e);
      return false;
    }
  }

  // Disable journal lock
  Future<bool> disableJournalLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_journalPinKey);
      await prefs.setBool(_journalLockEnabledKey, false);
      await prefs.remove(_journalUnlockedKey);
      LogService.info('Journal lock disabled successfully',
          tag: 'SecurityService');
      return true;
    } catch (e) {
      LogService.error('Error disabling journal lock',
          tag: 'SecurityService', error: e);
      return false;
    }
  }

  // Verify PIN for journal
  Future<bool> verifyJournalPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString(_journalPinKey);

      if (storedPin == null) return false;

      final isValid = storedPin == pin;

      if (isValid) {
        await _updateUnlockedTimestamp();
        LogService.info('Journal unlocked successfully',
            tag: 'SecurityService');
      }

      return isValid;
    } catch (e) {
      LogService.error('Error verifying journal PIN',
          tag: 'SecurityService', error: e);
      return false;
    }
  }

  // Check if journal has a PIN set
  Future<bool> hasJournalPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_journalPinKey);
    } catch (e) {
      LogService.warning('Error checking journal PIN',
          tag: 'SecurityService', error: e);
      return false;
    }
  }

  // Check if journal is currently unlocked
  Future<bool> isJournalUnlocked() async {
    try {
      if (!await isJournalLockEnabled()) return true;

      final prefs = await SharedPreferences.getInstance();
      final unlockedTimestamp = prefs.getInt(_journalUnlockedKey);

      if (unlockedTimestamp == null) return false;

      final unlockedTime =
          DateTime.fromMillisecondsSinceEpoch(unlockedTimestamp);
      final now = DateTime.now();

      // Check if auto-lock duration has passed
      return now.difference(unlockedTime) < _autoLockDuration;
    } catch (e) {
      LogService.warning('Error checking journal unlock status',
          tag: 'SecurityService', error: e);
      return false;
    }
  }

  // Lock the journal (clear unlocked timestamp)
  Future<void> lockJournal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_journalUnlockedKey);
      LogService.info('Journal locked', tag: 'SecurityService');
    } catch (e) {
      LogService.error('Error locking journal',
          tag: 'SecurityService', error: e);
    }
  }

  // Update the unlocked timestamp
  Future<void> _updateUnlockedTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _journalUnlockedKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      LogService.error('Error updating unlock timestamp',
          tag: 'SecurityService', error: e);
    }
  }

  // Attempt to unlock journal with PIN
  Future<bool> unlockJournalWithPin(String pin) async {
    try {
      if (!await isJournalLockEnabled()) return true;
      if (await isJournalUnlocked()) return true;

      return await verifyJournalPin(pin);
    } catch (e) {
      LogService.error('Error unlocking journal',
          tag: 'SecurityService', error: e);
      return false;
    }
  }

  // Get stored PIN (for setup dialog)
  Future<String?> getStoredPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_journalPinKey);
    } catch (e) {
      LogService.error('Error getting stored PIN',
          tag: 'SecurityService', error: e);
      return null;
    }
  }
}
