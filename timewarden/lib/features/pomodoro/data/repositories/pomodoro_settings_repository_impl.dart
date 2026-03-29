import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/log_service.dart';
import '../../domain/entities/pomodoro_settings.dart';
import '../../domain/repositories/pomodoro_settings_repository.dart';

class PomodoroSettingsRepositoryImpl implements PomodoroSettingsRepository {
  static const String _settingsKey = 'pomodoro_settings_json';

  @override
  Future<PomodoroSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSettings = prefs.getString(_settingsKey);

    if (rawSettings == null || rawSettings.trim().isEmpty) {
      return const PomodoroSettings();
    }

    try {
      final decoded = jsonDecode(rawSettings) as Map<String, dynamic>;
      return PomodoroSettings.fromJson(decoded);
    } catch (e) {
      LogService.debug(
        'PomodoroSettingsRepository: Invalid stored settings, using defaults: $e',
      );
      await prefs.remove(_settingsKey);
      return const PomodoroSettings();
    }
  }

  @override
  Future<void> saveSettings(PomodoroSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, payload);
  }
}
