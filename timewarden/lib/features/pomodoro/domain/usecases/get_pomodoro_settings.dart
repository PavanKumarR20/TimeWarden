import '../entities/pomodoro_settings.dart';
import '../repositories/pomodoro_settings_repository.dart';

class GetPomodoroSettings {
  final PomodoroSettingsRepository _repository;

  GetPomodoroSettings(this._repository);

  Future<PomodoroSettings> call() {
    return _repository.getSettings();
  }
}
