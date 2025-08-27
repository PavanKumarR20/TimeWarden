import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum PomodoroSoundType {
  sessionStart,
  sessionComplete,
  breakStart,
  breakComplete,
  finalBreakComplete,
  sessionPause,
  sessionResume,
  tick,
}

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isEnabled = true;
  double _volume = 0.8;

  // Initialize the audio service
  Future<void> initialize() async {
    print('AudioService: Initializing enhanced audio service');
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(_volume);
      print('AudioService: Initialization successful');
    } catch (e) {
      print('AudioService: Initialization failed: $e');
    }
  }

  // Set volume (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _audioPlayer.setVolume(_volume);
    print('AudioService: Volume set to $_volume');
  }

  // Enable/disable sounds
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    print('AudioService: Sounds ${enabled ? 'enabled' : 'disabled'}');
  }

  // Play unique Pomodoro sounds with rich haptic feedback
  Future<void> playPomodoroSound(PomodoroSoundType soundType) async {
    print(
        'AudioService: playPomodoroSound called with type: $soundType, enabled: $_isEnabled');

    if (!_isEnabled) {
      print('AudioService: Sounds are disabled, skipping playback');
      return;
    }

    try {
      print('AudioService: Playing enhanced sound for type: $soundType');

      switch (soundType) {
        case PomodoroSoundType.sessionStart:
          await _playSessionStartSound();
          break;
        case PomodoroSoundType.sessionComplete:
          await _playSessionCompleteSound();
          break;
        case PomodoroSoundType.breakStart:
          await _playBreakStartSound();
          break;
        case PomodoroSoundType.breakComplete:
          await _playBreakCompleteSound();
          break;
        case PomodoroSoundType.finalBreakComplete:
          await _playFinalBreakCompleteSound();
          break;
        case PomodoroSoundType.sessionPause:
          await _playSessionPauseSound();
          break;
        case PomodoroSoundType.sessionResume:
          await _playSessionResumeSound();
          break;
        case PomodoroSoundType.tick:
          await _playTickSound();
          break;
      }
    } catch (e) {
      print('Error playing Pomodoro sound: $e');
    }
  }

  // Enhanced sound implementations with audio files + haptic feedback
  Future<void> _playSessionStartSound() async {
    print('AudioService: Playing session start - Energizing rising pattern 🚀');

    try {
      // Play audio file
      await _audioPlayer.play(AssetSource('icons/audio/work_start.mp3'));
    } catch (e) {
      print('AudioService: Error playing work_start.mp3: $e');
    }

    // Rising energy pattern: light -> medium -> heavy
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 120));

    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));

    HapticFeedback.heavyImpact();

    // Add a finishing touch
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.selectionClick();
  }

  Future<void> _playSessionCompleteSound() async {
    print('AudioService: Playing session complete - Success celebration 🎉');

    try {
      // Play audio file
      await _audioPlayer.play(AssetSource('icons/audio/work_complete.mp3'));
    } catch (e) {
      print('AudioService: Error playing work_complete.mp3: $e');
    }

    // Success pattern: quick celebratory sequence
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 60));

    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 60));

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));

    // Final celebration
    HapticFeedback.mediumImpact();
  }

  Future<void> _playBreakStartSound() async {
    print(
        'AudioService: Playing break start - Gentle descending relaxation 🧘');

    try {
      // Play audio file
      await _audioPlayer.play(AssetSource('icons/audio/break_start.mp3'));
    } catch (e) {
      print('AudioService: Error playing break_start.mp3: $e');
    }

    // Descending relaxation pattern: heavy -> medium -> light
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 180));

    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 180));

    HapticFeedback.lightImpact();

    // Gentle finish
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.selectionClick();
  }

  Future<void> _playBreakCompleteSound() async {
    print('AudioService: Playing break complete - Back to work motivation 💪');

    try {
      // Play audio file
      await _audioPlayer.play(AssetSource('icons/audio/break_complete.mp3'));
    } catch (e) {
      print('AudioService: Error playing break_complete.mp3: $e');
    }

    // Motivation pattern: gentle buildup
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));

    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));

    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));

    HapticFeedback.heavyImpact();
  }

  Future<void> _playFinalBreakCompleteSound() async {
    print('AudioService: Playing final break complete - Victory fanfare 🏆');

    try {
      // Play audio file
      await _audioPlayer.play(AssetSource('icons/audio/session_complete.mp3'));
    } catch (e) {
      print('AudioService: Error playing session_complete.mp3: $e');
    }

    // Victory pattern: grand celebration
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));

    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));

    // Grand finale
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 70));

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 70));

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));

    // Victory finish
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 40));
    HapticFeedback.lightImpact();
  }

  Future<void> _playSessionPauseSound() async {
    print('AudioService: Playing session pause - Gentle pause ⏸️');

    // Pause pattern: descending
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
  }

  Future<void> _playSessionResumeSound() async {
    print('AudioService: Playing session resume - Ready to continue ▶️');

    // Resume pattern: ascending
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
  }

  Future<void> _playTickSound() async {
    // Simple tick (haptic only)
    HapticFeedback.selectionClick();
  }

  // Clean up resources
  Future<void> dispose() async {
    print('AudioService: Disposing audio service');
    await _audioPlayer.dispose();
  }
}
