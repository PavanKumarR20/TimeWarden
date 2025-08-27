import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class HapticService {
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
      if (kDebugMode) {
        print('HapticService: Light impact executed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HapticService: Light impact failed - $e');
      }
    }
  }

  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
      if (kDebugMode) {
        print('HapticService: Medium impact executed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HapticService: Medium impact failed - $e');
      }
    }
  }

  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
      if (kDebugMode) {
        print('HapticService: Heavy impact executed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HapticService: Heavy impact failed - $e');
      }
    }
  }

  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
      if (kDebugMode) {
        print('HapticService: Selection click executed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HapticService: Selection click failed - $e');
      }
    }
  }

  static Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
      if (kDebugMode) {
        print('HapticService: Vibrate executed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HapticService: Vibrate failed - $e');
      }
    }
  }

  // Specific haptic patterns for different actions
  static Future<void> habitCompleted() async {
    if (kDebugMode) {
      print('HapticService: Habit completed - triggering medium impact');
    }
    await mediumImpact();
  }

  static Future<void> habitUncompleted() async {
    if (kDebugMode) {
      print('HapticService: Habit uncompleted - triggering light impact');
    }
    await lightImpact();
  }

  static Future<void> buttonTap() async {
    if (kDebugMode) {
      print('HapticService: Button tap - triggering selection click');
    }
    await selectionClick();
  }

  static Future<void> successAction() async {
    if (kDebugMode) {
      print('HapticService: Success action - triggering heavy impact');
    }
    await heavyImpact();
  }

  static Future<void> errorAction() async {
    if (kDebugMode) {
      print('HapticService: Error action - triggering vibrate');
    }
    await vibrate();
  }
}
