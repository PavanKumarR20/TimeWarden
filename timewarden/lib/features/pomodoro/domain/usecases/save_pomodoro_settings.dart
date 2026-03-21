import '../entities/pomodoro_settings.dart';
import '../repositories/pomodoro_settings_repository.dart';

class SavePomodoroSettings {
  final PomodoroSettingsRepository _repository;

  SavePomodoroSettings(this._repository);

  Future<void> call(PomodoroSettings settings) {
    return _repository.saveSettings(settings);
  }
}
