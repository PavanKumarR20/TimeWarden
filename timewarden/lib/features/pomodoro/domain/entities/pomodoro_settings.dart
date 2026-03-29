import 'package:equatable/equatable.dart';

class PomodoroSettings extends Equatable {
  final int workDurationMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsUntilLongBreak;
  final bool enableNotifications;
  final bool enableSounds;
  final bool enableVibration;
  final double soundVolume;

  const PomodoroSettings({
    this.workDurationMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsUntilLongBreak = 4,
    this.enableNotifications = true,
    this.enableSounds = true,
    this.enableVibration = true,
    this.soundVolume = 0.8,
  });

  PomodoroSettings copyWith({
    int? workDurationMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsUntilLongBreak,
    bool? enableNotifications,
    bool? enableSounds,
    bool? enableVibration,
    double? soundVolume,
  }) {
    return PomodoroSettings(
      workDurationMinutes: workDurationMinutes ?? this.workDurationMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsUntilLongBreak:
          sessionsUntilLongBreak ?? this.sessionsUntilLongBreak,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSounds: enableSounds ?? this.enableSounds,
      enableVibration: enableVibration ?? this.enableVibration,
      soundVolume: soundVolume ?? this.soundVolume,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workDurationMinutes': workDurationMinutes,
      'shortBreakMinutes': shortBreakMinutes,
      'longBreakMinutes': longBreakMinutes,
      'sessionsUntilLongBreak': sessionsUntilLongBreak,
      'enableNotifications': enableNotifications,
      'enableSounds': enableSounds,
      'enableVibration': enableVibration,
      'soundVolume': soundVolume,
    };
  }

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) {
    return PomodoroSettings(
      workDurationMinutes: json['workDurationMinutes'] as int? ?? 25,
      shortBreakMinutes: json['shortBreakMinutes'] as int? ?? 5,
      longBreakMinutes: json['longBreakMinutes'] as int? ?? 15,
      sessionsUntilLongBreak: json['sessionsUntilLongBreak'] as int? ?? 4,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      enableSounds: json['enableSounds'] as bool? ?? true,
      enableVibration: json['enableVibration'] as bool? ?? true,
      soundVolume: (json['soundVolume'] as num?)?.toDouble() ?? 0.8,
    );
  }

  @override
  List<Object?> get props => [
        workDurationMinutes,
        shortBreakMinutes,
        longBreakMinutes,
        sessionsUntilLongBreak,
        enableNotifications,
        enableSounds,
        enableVibration,
        soundVolume,
      ];
}
