import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timewarden/features/pomodoro/data/repositories/pomodoro_settings_repository_impl.dart';
import 'package:timewarden/features/pomodoro/domain/entities/pomodoro_settings.dart';

void main() {
  late PomodoroSettingsRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = PomodoroSettingsRepositoryImpl();
  });

  group('PomodoroSettingsRepositoryImpl', () {
    test('returns default settings when storage is empty', () async {
      final settings = await repository.getSettings();

      expect(settings, equals(const PomodoroSettings()));
    });

    test('saves and loads settings from SharedPreferences', () async {
      const expected = PomodoroSettings(
        workDurationMinutes: 45,
        shortBreakMinutes: 10,
        longBreakMinutes: 20,
        sessionsUntilLongBreak: 3,
        enableNotifications: false,
        enableSounds: false,
        enableVibration: false,
        soundVolume: 0.4,
      );

      await repository.saveSettings(expected);
      final loaded = await repository.getSettings();

      expect(loaded, equals(expected));
    });

    test('falls back to defaults when stored JSON is invalid', () async {
      SharedPreferences.setMockInitialValues({
        'pomodoro_settings_json': 'not-a-json-payload',
      });
      repository = PomodoroSettingsRepositoryImpl();

      final settings = await repository.getSettings();
      final prefs = await SharedPreferences.getInstance();

      expect(settings, equals(const PomodoroSettings()));
      expect(prefs.getString('pomodoro_settings_json'), isNull);
    });
  });
}
