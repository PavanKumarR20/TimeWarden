import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'log_service.dart';

class HapticService {
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
      if (kDebugMode) {
        LogService.debug('HapticService: Light impact executed');
      }
    } catch (e) {
      if (kDebugMode) {
        LogService.debug('HapticService: Light impact failed - $e');
      }
    }
  }

  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
      if (kDebugMode) {
        LogService.debug('HapticService: Medium impact executed');
      }
    } catch (e) {
      if (kDebugMode) {
        LogService.debug('HapticService: Medium impact failed - $e');
      }
    }
  }

  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
      if (kDebugMode) {
        LogService.debug('HapticService: Heavy impact executed');
      }
    } catch (e) {
      if (kDebugMode) {
        LogService.debug('HapticService: Heavy impact failed - $e');
      }
    }
  }

  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
      if (kDebugMode) {
        LogService.debug('HapticService: Selection click executed');
      }
    } catch (e) {
      if (kDebugMode) {
        LogService.debug('HapticService: Selection click failed - $e');
      }
    }
  }

  static Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
      if (kDebugMode) {
        LogService.debug('HapticService: Vibrate executed');
      }
    } catch (e) {
      if (kDebugMode) {
        LogService.debug('HapticService: Vibrate failed - $e');
      }
    }
  }

  // Specific haptic patterns for different actions
  static Future<void> habitCompleted() async {
    if (kDebugMode) {
      LogService.debug(
          'HapticService: Habit completed - triggering heavy impact');
    }
    await heavyImpact();
  }

  static Future<void> habitUncompleted() async {
    if (kDebugMode) {
      LogService.debug(
          'HapticService: Habit uncompleted - triggering medium impact');
    }
    await mediumImpact();
  }

  static Future<void> buttonTap() async {
    if (kDebugMode) {
      LogService.debug('HapticService: Button tap - triggering medium impact');
    }
    await mediumImpact();
  }

  static Future<void> successAction() async {
    if (kDebugMode) {
      LogService.debug(
          'HapticService: Success action - triggering heavy impact');
    }
    await heavyImpact();
  }

  static Future<void> errorAction() async {
    if (kDebugMode) {
      LogService.debug('HapticService: Error action - triggering heavy impact');
    }
    await heavyImpact();
  }

  // Additional stronger haptic patterns
  static Future<void> pomodoroStart() async {
    if (kDebugMode) {
      LogService.debug(
          'HapticService: Pomodoro start - triggering heavy impact');
    }
    await heavyImpact();
  }

  static Future<void> pomodoroComplete() async {
    if (kDebugMode) {
      print(
          'HapticService: Pomodoro complete - triggering double heavy impact');
    }
    await heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await heavyImpact();
  }

  static Future<void> timerPause() async {
    if (kDebugMode) {
      LogService.debug('HapticService: Timer pause - triggering medium impact');
    }
    await mediumImpact();
  }

  static Future<void> navigationTap() async {
    if (kDebugMode) {
      LogService.debug(
          'HapticService: Navigation tap - triggering medium impact');
    }
    await mediumImpact();
  }
}
