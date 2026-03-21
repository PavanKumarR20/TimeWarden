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

            const SizedBox(height: 40),

            // Reset to Defaults
            SlideInAnimation(
              delay: const Duration(milliseconds: 200),
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
              minValue: 1,
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
              minValue: 1,
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

  void _updateSettings(PomodoroSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });

    context.read<PomodoroBloc>().add(PomodoroSettingsUpdated(_settings));
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
              });
              context
                  .read<PomodoroBloc>()
                  .add(PomodoroSettingsUpdated(_settings));
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
