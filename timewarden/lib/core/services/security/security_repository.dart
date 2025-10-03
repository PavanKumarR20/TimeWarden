import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../firebase_service.dart';
import '../log_service.dart';

class SecurityRepository {
  final FirebaseService _firebaseService;

  SecurityRepository(this._firebaseService);

  DocumentReference get _securityDoc {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) {
      LogService.error('User not authenticated for security operations',
          tag: 'SecurityRepository');
      throw Exception('User not authenticated');
    }
    LogService.info('Getting security document for user: $userId',
        tag: 'SecurityRepository');
    return _firebaseService.getUserSecurity(userId);
  }

  // Hash PIN for secure storage
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'timewarden_salt'); // Add salt for security
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Enable journal lock with PIN
  Future<bool> enableJournalLock(String pin) async {
    try {
      final hashedPin = _hashPin(pin);

      await _securityDoc.set({
        'journal_lock_enabled': true,
        'pin_hash': hashedPin,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      LogService.info('Journal lock enabled in Firestore',
          tag: 'SecurityRepository');
      return true;
    } catch (e) {
      LogService.error('Error enabling journal lock in Firestore',
          tag: 'SecurityRepository', error: e);
      return false;
    }
  }

  // Disable journal lock
  Future<bool> disableJournalLock() async {
    try {
      await _securityDoc.set({
        'journal_lock_enabled': false,
        'pin_hash': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      LogService.info('Journal lock disabled in Firestore',
          tag: 'SecurityRepository');
      return true;
    } catch (e) {
      LogService.error('Error disabling journal lock in Firestore',
          tag: 'SecurityRepository', error: e);
      return false;
    }
  }

  // Check if journal lock is enabled
  Future<bool> isJournalLockEnabled() async {
    try {
      final doc = await _securityDoc.get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      return data?['journal_lock_enabled'] ?? false;
    } catch (e) {
      LogService.warning('Error checking journal lock status in Firestore',
          tag: 'SecurityRepository', error: e);
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      LogService.info('Attempting to verify PIN', tag: 'SecurityRepository');
      final doc = await _securityDoc.get();

      if (!doc.exists) {
        LogService.warning('Security document does not exist',
            tag: 'SecurityRepository');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>?;
      final storedHash = data?['pin_hash'] as String?;

      if (storedHash == null) {
        LogService.warning('No PIN hash found in security document',
            tag: 'SecurityRepository');
        return false;
      }

      final hashedPin = _hashPin(pin);
      final isValid = storedHash == hashedPin;

      LogService.info('PIN verification result: $isValid',
          tag: 'SecurityRepository');

      if (isValid) {
        LogService.info('PIN verified successfully, updating unlock timestamp',
            tag: 'SecurityRepository');
        // Update last unlock timestamp
        await _securityDoc.set({
          'last_unlock_timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return isValid;
    } catch (e) {
      LogService.error('Error verifying PIN in Firestore',
          tag: 'SecurityRepository', error: e);
      return false;
    }
  }

  // Check if currently unlocked (within auto-lock duration)
  Future<bool> isCurrentlyUnlocked() async {
    try {
      if (!await isJournalLockEnabled()) return true;

      final doc = await _securityDoc.get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      final lastUnlock = data?['last_unlock_timestamp'] as Timestamp?;

      if (lastUnlock == null) return false;

      final lastUnlockTime = lastUnlock.toDate();
      final now = DateTime.now();
      const autoLockDuration = Duration(minutes: 5);

      return now.difference(lastUnlockTime) < autoLockDuration;
    } catch (e) {
      LogService.warning('Error checking unlock status in Firestore',
          tag: 'SecurityRepository', error: e);
      return false;
    }
  }

  // Lock (clear unlock timestamp)
  Future<void> lock() async {
    try {
      await _securityDoc.set({
        'last_unlock_timestamp': FieldValue.delete(),
      }, SetOptions(merge: true));

      LogService.info('Locked in Firestore', tag: 'SecurityRepository');
    } catch (e) {
      LogService.error('Error locking in Firestore',
          tag: 'SecurityRepository', error: e);
    }
  }

  // Get security settings
  Future<Map<String, dynamic>?> getSecuritySettings() async {
    try {
      final doc = await _securityDoc.get();
      if (!doc.exists) return null;

      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      LogService.error('Error getting security settings from Firestore',
          tag: 'SecurityRepository', error: e);
      return null;
    }
  }
}
