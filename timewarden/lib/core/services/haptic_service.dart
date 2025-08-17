import 'package:flutter/services.dart';

class HapticService {
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Haptic feedback not supported on this device
    }
  }

  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Haptic feedback not supported on this device
    }
  }

  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Haptic feedback not supported on this device
    }
  }

  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Haptic feedback not supported on this device
    }
  }

  static Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      // Haptic feedback not supported on this device
    }
  }

  // Specific haptic patterns for different actions
  static Future<void> habitCompleted() async {
    await mediumImpact();
  }

  static Future<void> habitUncompleted() async {
    await lightImpact();
  }

  static Future<void> buttonTap() async {
    await selectionClick();
  }

  static Future<void> successAction() async {
    await heavyImpact();
  }

  static Future<void> errorAction() async {
    await vibrate();
  }
}
