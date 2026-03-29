import '../log_service.dart';
import '../firebase_service.dart';
import 'security_repository.dart';

class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();

  late final SecurityRepository _repository;

  SecurityService._() {
    _repository = SecurityRepository(FirebaseService());
  }

  // Check if journal lock is enabled
  Future<bool> isJournalLockEnabled() async {
    return await _repository.isJournalLockEnabled();
  }

  // Enable journal lock with PIN
  Future<bool> enableJournalLock(String pin) async {
    return await _repository.enableJournalLock(pin);
  }

  // Disable journal lock
  Future<bool> disableJournalLock() async {
    return await _repository.disableJournalLock();
  }

  // Verify PIN for journal
  Future<bool> verifyJournalPin(String pin) async {
    return await _repository.verifyPin(pin);
  }

  // Check if journal has a PIN set
  Future<bool> hasJournalPin() async {
    return await _repository.isJournalLockEnabled();
  }

  // Check if journal is currently unlocked
  Future<bool> isJournalUnlocked() async {
    return await _repository.isCurrentlyUnlocked();
  }

  // Lock the journal (clear unlocked timestamp)
  Future<void> lockJournal() async {
    await _repository.lock();
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

  // Get security settings
  Future<Map<String, dynamic>?> getSecuritySettings() async {
    return await _repository.getSecuritySettings();
  }
}
