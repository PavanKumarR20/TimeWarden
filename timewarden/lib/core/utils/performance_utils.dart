import 'dart:developer' as developer;

/// Utility class for performance monitoring and optimization
class PerformanceUtils {
  static final Map<String, DateTime> _operationStartTimes = {};
  static final Map<String, List<int>> _operationDurations = {};

  /// Start timing an operation
  static void startTiming(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  /// End timing an operation and log the duration
  static void endTiming(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      // Store duration for analysis
      _operationDurations.putIfAbsent(operationName, () => []);
      _operationDurations[operationName]!.add(duration);

      // Log performance
      developer.log(
        'Operation $operationName took ${duration}ms',
        name: 'Performance',
      );

      // Keep only last 50 measurements to prevent memory leaks
      if (_operationDurations[operationName]!.length > 50) {
        _operationDurations[operationName]!.removeAt(0);
      }

      _operationStartTimes.remove(operationName);
    }
  }

  /// Get average duration for an operation
  static double? getAverageDuration(String operationName) {
    final durations = _operationDurations[operationName];
    if (durations == null || durations.isEmpty) return null;

    final sum = durations.reduce((a, b) => a + b);
    return sum / durations.length;
  }

  /// Wrapper for timing a future operation
  static Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startTiming(operationName);
    try {
      final result = await operation();
      endTiming(operationName);
      return result;
    } catch (e) {
      endTiming(operationName);
      rethrow;
    }
  }

  /// Check if device has low memory
  static bool isLowMemoryDevice() {
    // This is a simplified check - in production you might want to use
    // platform-specific APIs to get actual memory information
    return false; // Default to false for now
  }

  /// Debounce function calls to improve performance
  static final Map<String, DateTime> _lastCallTimes = {};

  static bool shouldExecute(String key, {int debounceMs = 300}) {
    final now = DateTime.now();
    final lastCall = _lastCallTimes[key];

    if (lastCall == null ||
        now.difference(lastCall).inMilliseconds >= debounceMs) {
      _lastCallTimes[key] = now;
      return true;
    }

    return false;
  }

  /// Clear performance data to free memory
  static void clearPerformanceData() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _lastCallTimes.clear();
  }

  /// Get performance summary
  static Map<String, dynamic> getPerformanceSummary() {
    final summary = <String, dynamic>{};

    for (final operation in _operationDurations.keys) {
      final avg = getAverageDuration(operation);
      final count = _operationDurations[operation]!.length;

      summary[operation] = {
        'averageDuration': avg,
        'callCount': count,
        'unit': 'ms',
      };
    }

    return summary;
  }
}
