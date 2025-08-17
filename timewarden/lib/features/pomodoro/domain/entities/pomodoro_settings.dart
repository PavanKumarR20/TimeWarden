import 'package:equatable/equatable.dart';

class PomodoroSettings extends Equatable {
  final int workDurationMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsUntilLongBreak;
  final bool autoStartBreaks;
  final bool autoStartWork;
  final bool enableNotifications;
  final bool enableSounds;
  final bool enableVibration;
  final double soundVolume;
  final String selectedSound;

  const PomodoroSettings({
    this.workDurationMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsUntilLongBreak = 4,
    this.autoStartBreaks = false,
    this.autoStartWork = false,
    this.enableNotifications = true,
    this.enableSounds = true,
    this.enableVibration = true,
    this.soundVolume = 0.8,
    this.selectedSound = 'bell',
  });

  static const List<String> availableSounds = [
    'bell',
    'chime',
    'ding',
    'notification',
    'beep',
  ];

  PomodoroSettings copyWith({
    int? workDurationMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsUntilLongBreak,
    bool? autoStartBreaks,
    bool? autoStartWork,
    bool? enableNotifications,
    bool? enableSounds,
    bool? enableVibration,
    double? soundVolume,
    String? selectedSound,
  }) {
    return PomodoroSettings(
      workDurationMinutes: workDurationMinutes ?? this.workDurationMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsUntilLongBreak:
          sessionsUntilLongBreak ?? this.sessionsUntilLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartWork: autoStartWork ?? this.autoStartWork,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSounds: enableSounds ?? this.enableSounds,
      enableVibration: enableVibration ?? this.enableVibration,
      soundVolume: soundVolume ?? this.soundVolume,
      selectedSound: selectedSound ?? this.selectedSound,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workDurationMinutes': workDurationMinutes,
      'shortBreakMinutes': shortBreakMinutes,
      'longBreakMinutes': longBreakMinutes,
      'sessionsUntilLongBreak': sessionsUntilLongBreak,
      'autoStartBreaks': autoStartBreaks,
      'autoStartWork': autoStartWork,
      'enableNotifications': enableNotifications,
      'enableSounds': enableSounds,
      'enableVibration': enableVibration,
      'soundVolume': soundVolume,
      'selectedSound': selectedSound,
    };
  }

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) {
    return PomodoroSettings(
      workDurationMinutes: json['workDurationMinutes'] as int? ?? 25,
      shortBreakMinutes: json['shortBreakMinutes'] as int? ?? 5,
      longBreakMinutes: json['longBreakMinutes'] as int? ?? 15,
      sessionsUntilLongBreak: json['sessionsUntilLongBreak'] as int? ?? 4,
      autoStartBreaks: json['autoStartBreaks'] as bool? ?? false,
      autoStartWork: json['autoStartWork'] as bool? ?? false,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      enableSounds: json['enableSounds'] as bool? ?? true,
      enableVibration: json['enableVibration'] as bool? ?? true,
      soundVolume: (json['soundVolume'] as num?)?.toDouble() ?? 0.8,
      selectedSound: json['selectedSound'] as String? ?? 'bell',
    );
  }

  @override
  List<Object?> get props => [
        workDurationMinutes,
        shortBreakMinutes,
        longBreakMinutes,
        sessionsUntilLongBreak,
        autoStartBreaks,
        autoStartWork,
        enableNotifications,
        enableSounds,
        enableVibration,
        soundVolume,
        selectedSound,
      ];
}
