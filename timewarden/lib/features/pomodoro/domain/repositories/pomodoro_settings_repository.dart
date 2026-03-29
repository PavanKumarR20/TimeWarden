import '../entities/pomodoro_settings.dart';

abstract class PomodoroSettingsRepository {
  Future<PomodoroSettings> getSettings();

  Future<void> saveSettings(PomodoroSettings settings);
}
