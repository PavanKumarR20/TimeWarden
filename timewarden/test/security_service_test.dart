import 'package:flutter_test/flutter_test.dart';
import 'package:timewarden/core/services/security/security_service.dart';

void main() {
  group('SecurityService Tests', () {
    late SecurityService securityService;

    setUp(() {
      securityService = SecurityService.instance;
    });

    test('should initialize with journal lock disabled', () async {
      // Journal lock should be disabled by default
      final isEnabled = await securityService.isJournalLockEnabled();
      expect(isEnabled, false);
    });

    test('should be able to enable journal lock', () async {
      // Enable journal lock
      await securityService.setJournalLockEnabled(true);

      // Verify it's enabled
      final isEnabled = await securityService.isJournalLockEnabled();
      expect(isEnabled, true);

      // Clean up
      await securityService.setJournalLockEnabled(false);
    });

    test('should be able to set and verify PIN', () async {
      const testPin = '123456';

      // Set PIN
      await securityService.setJournalPin(testPin);

      // Verify correct PIN
      final isValidCorrect = await securityService.verifyJournalPin(testPin);
      expect(isValidCorrect, true);

      // Verify incorrect PIN
      final isValidIncorrect = await securityService.verifyJournalPin('654321');
      expect(isValidIncorrect, false);

      // Clean up
      await securityService.setJournalLockEnabled(false);
    });

    test('should handle journal unlock state correctly', () async {
      // Enable lock
      await securityService.setJournalLockEnabled(true);

      // Should be locked initially
      final isUnlockedInitially = await securityService.isJournalUnlocked();
      expect(isUnlockedInitially, false);

      // Set PIN and verify (this should unlock)
      const testPin = '123456';
      await securityService.setJournalPin(testPin);
      await securityService.verifyJournalPin(testPin);

      // Should be unlocked now
      final isUnlockedAfterAuth = await securityService.isJournalUnlocked();
      expect(isUnlockedAfterAuth, true);

      // Lock manually
      await securityService.lockJournal();

      // Should be locked again
      final isUnlockedAfterLock = await securityService.isJournalUnlocked();
      expect(isUnlockedAfterLock, false);

      // Clean up
      await securityService.setJournalLockEnabled(false);
    });

    test('should determine correct lock type', () async {
      // No lock initially
      var lockType = await securityService.getJournalLockType();
      expect(lockType, JournalLockType.none);

      // Enable lock and set PIN
      await securityService.setJournalLockEnabled(true);
      await securityService.setJournalPin('123456');

      lockType = await securityService.getJournalLockType();
      expect(lockType, JournalLockType.pin);

      // Clean up
      await securityService.setJournalLockEnabled(false);
    });
  });
}
