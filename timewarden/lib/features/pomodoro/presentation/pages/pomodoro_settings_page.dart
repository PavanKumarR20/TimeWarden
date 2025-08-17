import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/pomodoro_settings.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/widgets/animations.dart';
import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_event.dart';
import '../bloc/pomodoro_state.dart';

class PomodoroSettingsPage extends StatefulWidget {
  const PomodoroSettingsPage({super.key});

  @override
  State<PomodoroSettingsPage> createState() => _PomodoroSettingsPageState();
}

class _PomodoroSettingsPageState extends State<PomodoroSettingsPage> {
  late PomodoroSettings _settings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<PomodoroBloc>().state;
    if (state is PomodoroReady) {
      _settings = state.settings;
    } else if (state is PomodoroRunning) {
      _settings = state.settings;
    } else if (state is PomodoroPaused) {
      _settings = state.settings;
    } else {
      _settings = const PomodoroSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Settings'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer Duration Settings
            SlideInAnimation(
              child: _buildTimerSettings(context),
            ),

            const SizedBox(height: 24),

            // Automation Settings
            SlideInAnimation(
              delay: const Duration(milliseconds: 100),
              child: _buildAutomationSettings(context),
            ),

            const SizedBox(height: 24),

            // Notification Settings
            SlideInAnimation(
              delay: const Duration(milliseconds: 200),
              child: _buildNotificationSettings(context),
            ),

            const SizedBox(height: 24),

            // Sound Settings
            SlideInAnimation(
              delay: const Duration(milliseconds: 300),
              child: _buildSoundSettings(context),
            ),

            const SizedBox(height: 40),

            // Reset to Defaults
            SlideInAnimation(
              delay: const Duration(milliseconds: 400),
              child: Center(
                child: TextButton(
                  onPressed: _resetToDefaults,
                  child: const Text('Reset to Defaults'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Timer Durations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Work Duration
            _buildDurationSetting(
              context,
              'Focus Session',
              _settings.workDurationMinutes,
              (value) => _updateSettings(
                  _settings.copyWith(workDurationMinutes: value)),
              Colors.red.shade400,
              minValue: 5,
              maxValue: 60,
            ),

            const SizedBox(height: 16),

            // Short Break Duration
            _buildDurationSetting(
              context,
              'Short Break',
              _settings.shortBreakMinutes,
              (value) =>
                  _updateSettings(_settings.copyWith(shortBreakMinutes: value)),
              Colors.green.shade400,
              minValue: 1,
              maxValue: 15,
            ),

            const SizedBox(height: 16),

            // Long Break Duration
            _buildDurationSetting(
              context,
              'Long Break',
              _settings.longBreakMinutes,
              (value) =>
                  _updateSettings(_settings.copyWith(longBreakMinutes: value)),
              Colors.blue.shade400,
              minValue: 5,
              maxValue: 30,
            ),

            const SizedBox(height: 16),

            // Sessions until long break
            _buildDurationSetting(
              context,
              'Sessions until Long Break',
              _settings.sessionsUntilLongBreak,
              (value) => _updateSettings(
                  _settings.copyWith(sessionsUntilLongBreak: value)),
              Colors.purple.shade400,
              minValue: 2,
              maxValue: 8,
              suffix: 'sessions',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSetting(
    BuildContext context,
    String title,
    int value,
    Function(int) onChanged,
    Color color, {
    int minValue = 1,
    int maxValue = 60,
    String suffix = 'min',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                '$value $suffix',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
            inactiveTrackColor: color.withOpacity(0.3),
          ),
          child: Slider(
            value: value.toDouble(),
            min: minValue.toDouble(),
            max: maxValue.toDouble(),
            divisions: maxValue - minValue,
            onChanged: (newValue) {
              HapticService.selectionClick();
              onChanged(newValue.round());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAutomationSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.autorenew,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Automation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSwitchSetting(
              context,
              'Auto-start Breaks',
              'Automatically start break sessions',
              _settings.autoStartBreaks,
              (value) =>
                  _updateSettings(_settings.copyWith(autoStartBreaks: value)),
            ),
            const SizedBox(height: 16),
            _buildSwitchSetting(
              context,
              'Auto-start Work',
              'Automatically start work sessions after breaks',
              _settings.autoStartWork,
              (value) =>
                  _updateSettings(_settings.copyWith(autoStartWork: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSwitchSetting(
              context,
              'Enable Notifications',
              'Show notifications when sessions complete',
              _settings.enableNotifications,
              (value) => _updateSettings(
                  _settings.copyWith(enableNotifications: value)),
            ),
            const SizedBox(height: 16),
            _buildSwitchSetting(
              context,
              'Enable Vibration',
              'Vibrate when sessions complete',
              _settings.enableVibration,
              (value) =>
                  _updateSettings(_settings.copyWith(enableVibration: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.volume_up_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sounds',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSwitchSetting(
              context,
              'Enable Sounds',
              'Play sounds when sessions complete',
              _settings.enableSounds,
              (value) =>
                  _updateSettings(_settings.copyWith(enableSounds: value)),
            ),
            if (_settings.enableSounds) ...[
              const SizedBox(height: 16),

              // Volume Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volume',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _settings.soundVolume,
                    onChanged: (value) {
                      HapticService.selectionClick();
                      _updateSettings(_settings.copyWith(soundVolume: value));
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Sound Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Sound',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...PomodoroSettings.availableSounds.map((sound) {
                    return RadioListTile<String>(
                      title: Text(sound.toUpperCase()),
                      value: sound,
                      groupValue: _settings.selectedSound,
                      onChanged: (value) {
                        if (value != null) {
                          HapticService.selectionClick();
                          _updateSettings(
                              _settings.copyWith(selectedSound: value));
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (newValue) {
            HapticService.selectionClick();
            onChanged(newValue);
          },
        ),
      ],
    );
  }

  void _updateSettings(PomodoroSettings newSettings) {
    setState(() {
      _settings = newSettings;
      _hasChanges = true;
    });
  }

  void _saveSettings() {
    HapticService.successAction();
    context.read<PomodoroBloc>().add(PomodoroSettingsUpdated(_settings));
    setState(() {
      _hasChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetToDefaults() {
    HapticService.buttonTap();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
            'Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _settings = const PomodoroSettings();
                _hasChanges = true;
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
