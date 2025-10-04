/// Debug utilities for development
/// This file provides debug-specific utilities that are only active in debug builds

import 'package:flutter/foundation.dart';

class DebugUtils {
  /// Print debug messages only in debug mode
  static void debugPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  /// Print debug messages with prefix only in debug mode
  static void debugPrintWithPrefix(String prefix, String message) {
    if (kDebugMode) {
      print('[$prefix] $message');
    }
  }

  /// Print debug messages with timestamp only in debug mode
  static void debugPrintWithTimestamp(String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      print('[$timestamp] $message');
    }
  }
}
