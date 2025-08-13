import 'dart:developer' as developer;

/// Centralized logging service for the application
class LogService {
  static const String _appName = 'TimeWarden';

  /// Log debug information
  static void debug(String message, {String? tag, Object? error}) {
    developer.log(
      message,
      name: _appName,
      level: 500, // Debug level
      error: error,
      time: DateTime.now(),
    );
  }

  /// Log informational messages
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: _appName,
      level: 800, // Info level
      time: DateTime.now(),
    );
  }

  /// Log warnings
  static void warning(String message, {String? tag, Object? error}) {
    developer.log(
      message,
      name: _appName,
      level: 900, // Warning level
      error: error,
      time: DateTime.now(),
    );
  }

  /// Log errors
  static void error(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _appName,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  /// Log authentication events
  static void auth(String message, {Object? error}) {
    if (error != null) {
      LogService.error('[AUTH] $message', error: error);
    } else {
      info('[AUTH] $message');
    }
  }

  /// Log habits-related events
  static void habits(String message, {Object? error}) {
    if (error != null) {
      LogService.error('[HABITS] $message', error: error);
    } else {
      info('[HABITS] $message');
    }
  }

  /// Log Firebase-related events
  static void firebase(String message, {Object? error}) {
    if (error != null) {
      LogService.error('[FIREBASE] $message', error: error);
    } else {
      info('[FIREBASE] $message');
    }
  }
}
