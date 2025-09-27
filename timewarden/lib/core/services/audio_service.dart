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
      // Set player mode for background playback
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      print('AudioService: ReleaseMode set to stop');

      // Set audio category for background playback (important for background audio)
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      print(
          'AudioService: PlayerMode set to mediaPlayer for background capability');

      // Configure audio session for alerts/notifications
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.duckOthers,
              AVAudioSessionOptions.defaultToSpeaker,
            },
          ),
        ),
      );
      print('AudioService: Audio context configured for notifications');

      // Set initial volume
      await _audioPlayer.setVolume(_volume);
      print('AudioService: Volume set to $_volume');

      // Test audio capability by trying to load a small audio asset
      try {
        final source = AssetSource('audio/work_start.mp3');
        print('AudioService: Testing asset path: audio/work_start.mp3');
        await _audioPlayer.setSource(source);
        print('AudioService: Test audio file loaded successfully');
        await _audioPlayer.stop(); // Don't play it, just test loading
      } catch (e) {
        print('AudioService: WARNING - Test audio file failed to load: $e');
        print(
            'AudioService: This could indicate missing audio files or permission issues');

        // Try alternative path with icons/ prefix (legacy)
        try {
          final altSource = AssetSource('icons/audio/work_start.mp3');
          print(
              'AudioService: Testing legacy path: icons/audio/work_start.mp3');
          await _audioPlayer.setSource(altSource);
          print('AudioService: Legacy path worked!');
          await _audioPlayer.stop();
        } catch (e2) {
          print('AudioService: Legacy path also failed: $e2');
        }
      }

      print('AudioService: Initialization successful');
    } catch (e) {
      print('AudioService: Initialization failed: $e');
      print('AudioService: Audio functionality may not work properly');
    }
  } // Set volume (0.0 to 1.0)

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

      // Ensure audio context is configured for alerts
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );

      // Add immediate test for session start
      if (soundType == PomodoroSoundType.sessionStart) {
        print('AudioService: === TESTING AUDIO PLAYBACK ===');
        await _testAudioPlayback();
      }

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

  // Test audio playback function
  Future<void> _testAudioPlayback() async {
    print('AudioService: Testing audio playback...');
    try {
      // Test with direct path
      print('AudioService: Trying AssetSource(audio/work_start.mp3)');
      await _audioPlayer.play(AssetSource('audio/work_start.mp3'));
      print('AudioService: SUCCESS - Audio played with audio/ path');
      return;
    } catch (e) {
      print('AudioService: Failed with audio/ path: $e');
    }

    // Test with legacy icons path
    try {
      print('AudioService: Trying AssetSource(icons/audio/work_start.mp3)');
      await _audioPlayer.play(AssetSource('icons/audio/work_start.mp3'));
      print(
          'AudioService: SUCCESS - Audio played with legacy icons/audio/ path');
      return;
    } catch (e) {
      print('AudioService: Failed with legacy icons/audio/ path: $e');
    }

    print('AudioService: All audio path tests failed');
  }

  // Enhanced sound implementations with audio files + haptic feedback
  Future<void> _playSessionStartSound() async {
    print('AudioService: Playing session start - Energizing rising pattern 🚀');

    try {
      // Stop any currently playing audio first
      await _audioPlayer.stop();

      // Play audio file
      print('AudioService: Attempting to play work_start.mp3');
      final source = AssetSource('audio/work_start.mp3');
      await _audioPlayer.play(source);
      print('AudioService: work_start.mp3 started playing successfully');
    } catch (e) {
      print('AudioService: Error playing work_start.mp3: $e');
      // Continue with haptic feedback even if audio fails
    }

    // Rising energy pattern: light -> medium -> heavy
    try {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 120));

      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 120));

      HapticFeedback.heavyImpact();

      // Add a finishing touch
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.selectionClick();
    } catch (e) {
      print('AudioService: Error with haptic feedback: $e');
    }
  }

  Future<void> _playSessionCompleteSound() async {
    print('AudioService: Playing session complete - Success celebration 🎉');

    try {
      // Stop any currently playing audio first
      await _audioPlayer.stop();

      // Play audio file
      print('AudioService: Attempting to play work_complete.mp3');
      final source = AssetSource('audio/work_complete.mp3');
      await _audioPlayer.play(source);
      print('AudioService: work_complete.mp3 started playing successfully');
    } catch (e) {
      print('AudioService: Error playing work_complete.mp3: $e');
      // Continue with haptic feedback even if audio fails
    }

    // Success pattern: quick celebratory sequence
    try {
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
    } catch (e) {
      print('AudioService: Error with haptic feedback: $e');
    }
  }

  Future<void> _playBreakStartSound() async {
    print(
        'AudioService: Playing break start - Gentle descending relaxation 🧘');

    try {
      // Play audio file
      await _audioPlayer.play(AssetSource('audio/break_start.mp3'));
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
      await _audioPlayer.play(AssetSource('audio/break_complete.mp3'));
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
      await _audioPlayer.play(AssetSource('audio/session_complete.mp3'));
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

    try {
      // Stop any currently playing audio first
      await _audioPlayer.stop();

      // Play work start audio for resume (same energizing sound)
      print('AudioService: Attempting to play work_start.mp3 for resume');
      final source = AssetSource('audio/work_start.mp3');
      await _audioPlayer.play(source);
      print(
          'AudioService: work_start.mp3 started playing successfully for resume');
    } catch (e) {
      print('AudioService: Error playing work_start.mp3 for resume: $e');
      // Continue with haptic feedback even if audio fails
    }

    // Resume pattern: ascending haptic feedback
    try {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('AudioService: Error with haptic feedback for resume: $e');
    }
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
