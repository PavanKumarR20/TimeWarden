import 'package:flutter/foundation.dart';

/// Utility class for data validation and security checks
class SecurityUtils {
  /// Validates email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validates password strength
  static bool isValidPassword(String password) {
    // At least 8 characters, contains uppercase, lowercase, and number
    if (password.length < 8) return false;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));

    return hasUppercase && hasLowercase && hasNumbers;
  }

  /// Sanitizes user input to prevent injection attacks
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"' "'" ';]'),
            '') // Remove potentially dangerous characters
        .trim();
  }

  /// Validates habit name input
  static bool isValidHabitName(String name) {
    final sanitized = sanitizeInput(name);
    return sanitized.isNotEmpty &&
        sanitized.length <= 50 &&
        sanitized.length >= 1;
  }

  /// Validates journal entry content
  static bool isValidJournalContent(String content) {
    final sanitized = sanitizeInput(content);
    return sanitized.length <= 10000; // Max 10k characters
  }

  /// Checks if string contains only safe characters
  static bool containsOnlySafeCharacters(String input) {
    final safeCharRegex =
        RegExp(r'^[a-zA-Z0-9\s\-_.,:;!?()[\]{}@#$%&*+=|~`^]+$');
    return safeCharRegex.hasMatch(input);
  }

  /// Validates user ID format
  static bool isValidUserId(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    // Firebase UIDs are typically 28 characters
    return userId.length >= 20 && userId.length <= 40;
  }

  /// Prevents debug mode information leakage
  static void secureLog(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('${tag ?? 'App'}: $message');
    }
    // In release mode, logs are automatically stripped
  }

  /// Rate limiting helper for sensitive operations
  static final Map<String, DateTime> _lastOperationTime = {};

  static bool canPerformOperation(String operationKey,
      {int cooldownSeconds = 1}) {
    final now = DateTime.now();
    final lastTime = _lastOperationTime[operationKey];

    if (lastTime == null ||
        now.difference(lastTime).inSeconds >= cooldownSeconds) {
      _lastOperationTime[operationKey] = now;
      return true;
    }

    return false;
  }

  /// Clear sensitive data from memory
  static void clearSensitiveData(List<String?> data) {
    for (int i = 0; i < data.length; i++) {
      data[i] = null;
    }
  }
}
