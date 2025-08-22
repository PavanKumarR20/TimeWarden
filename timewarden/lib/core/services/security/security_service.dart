import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../log_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecurityService {
  static const String _journalLockEnabledKey = 'journal_lock_enabled';
  static const String _journalPinKey = 'journal_pin_hash';
  static const String _journalBiometricKey = 'journal_biometric_enabled';
  static const String _journalUnlockedKey = 'journal_unlocked_timestamp';

  // Auto-lock after 5 minutes of inactivity
  static const Duration _autoLockDuration = Duration(minutes: 5);

  final LocalAuthentication _localAuth = LocalAuthentication();

  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();
  SecurityService._();

  // Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock your journal',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        await _updateUnlockedTimestamp();
      }

      return isAuthenticated;
    } on PlatformException catch (e) {
      LogService.warning('Biometric authentication error', tag: 'SecurityService', error: e);
      return false;
    }
  }

  // Check if journal lock is enabled
  Future<bool> isJournalLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_journalLockEnabledKey) ?? false;
  }

  // Enable/disable journal lock
  Future<void> setJournalLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journalLockEnabledKey, enabled);

    if (!enabled) {
      // Clear all lock-related data when disabling
      await prefs.remove(_journalPinKey);
      await prefs.remove(_journalBiometricKey);
      await prefs.remove(_journalUnlockedKey);
    }
  }

  // Check if biometric authentication is enabled for journal
  Future<bool> isBiometricEnabledForJournal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_journalBiometricKey) ?? false;
  }

  // Enable/disable biometric authentication for journal
  Future<void> setBiometricEnabledForJournal(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journalBiometricKey, enabled);
  }

  // Set PIN for journal
  Future<void> setJournalPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hashedPin = _hashPin(pin);
    await prefs.setString(_journalPinKey, hashedPin);
  }

  // Verify PIN for journal
  Future<bool> verifyJournalPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_journalPinKey);

    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    final isValid = storedHash == inputHash;

    if (isValid) {
      await _updateUnlockedTimestamp();
    }

    return isValid;
  }

  // Check if journal has a PIN set
  Future<bool> hasJournalPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_journalPinKey);
  }

  // Check if journal is currently unlocked
  Future<bool> isJournalUnlocked() async {
    if (!await isJournalLockEnabled()) return true;

    final prefs = await SharedPreferences.getInstance();
    final unlockedTimestamp = prefs.getInt(_journalUnlockedKey);

    if (unlockedTimestamp == null) return false;

    final unlockedTime = DateTime.fromMillisecondsSinceEpoch(unlockedTimestamp);
    final now = DateTime.now();

    // Check if auto-lock duration has passed
    return now.difference(unlockedTime) < _autoLockDuration;
  }

  // Lock the journal (clear unlocked timestamp)
  Future<void> lockJournal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_journalUnlockedKey);
  }

  // Update the unlocked timestamp
  Future<void> _updateUnlockedTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _journalUnlockedKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Get lock type (biometric, pin, or none)
  Future<JournalLockType> getJournalLockType() async {
    if (!await isJournalLockEnabled()) return JournalLockType.none;

    final hasBiometric = await isBiometricEnabledForJournal();
    final hasPin = await hasJournalPin();

    if (hasBiometric && await isBiometricAvailable()) {
      return JournalLockType.biometric;
    } else if (hasPin) {
      return JournalLockType.pin;
    } else {
      return JournalLockType.none;
    }
  }

  // Attempt to unlock journal with available methods
  Future<bool> unlockJournal() async {
    if (!await isJournalLockEnabled()) return true;
    if (await isJournalUnlocked()) return true;

    final lockType = await getJournalLockType();

    switch (lockType) {
      case JournalLockType.biometric:
        return await authenticateWithBiometrics();
      case JournalLockType.pin:
        // PIN authentication should be handled by UI
        return false;
      case JournalLockType.none:
        return true;
    }
  }
}

enum JournalLockType {
  none,
  pin,
  biometric,
}
