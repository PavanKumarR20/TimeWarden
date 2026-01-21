import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/widgets/animations.dart';
import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_event.dart';
import '../bloc/pomodoro_state.dart';
import 'pomodoro_settings_page.dart';
import 'pomodoro_statistics_page.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  final TextEditingController _taskController = TextEditingController();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      print(
          'PomodoroPage: App resumed - checking if session completed while backgrounded');
      // When app resumes, check if session completed while backgrounded
      if (mounted) {
        context.read<PomodoroBloc>().add(const PomodoroTimeSyncRequested());
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      print(
          'PomodoroPage: App backgrounded - scheduled notification will handle completion');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      context.read<PomodoroBloc>().add(const PomodoroLoadRequested());
      _hasInitialized = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressController.dispose();
    _pulseController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              HapticService.buttonTap();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<PomodoroBloc>(),
                    child: const PomodoroStatisticsPage(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              HapticService.buttonTap();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<PomodoroBloc>(),
                    child: const PomodoroSettingsPage(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<PomodoroBloc, PomodoroState>(
        listener: (context, state) {
          if (state is PomodoroError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }

          // Show break prompt dialog when work session completes
          if (state is PomodoroSessionCompleted &&
              state.completedSession.type == PomodoroType.work) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showBreakPromptDialog(context, state);
            });
          }
        },
        builder: (context, state) {
          if (state is PomodoroLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PomodoroSessionCompleted) {
            return _buildSessionCompletedView(context, state);
          }

          return _buildMainView(context, state);
        },
      ),
    );
  }

  Widget _buildMainView(BuildContext context, PomodoroState state) {
    PomodoroSession? currentSession;
    bool isRunning = false;
    bool isPaused = false;

    if (state is PomodoroRunning) {
      currentSession = state.currentSession;
      isRunning = true;
    } else if (state is PomodoroPaused) {
      currentSession = state.currentSession;
      isPaused = true;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Session Type Indicator
          if (currentSession != null) ...[
            FadeInAnimation(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getSessionColor(currentSession.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getSessionColor(currentSession.type),
                    width: 2,
                  ),
                ),
                child: Text(
                  currentSession.displayType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _getSessionColor(currentSession.type),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cycle Indicator
            FadeInAnimation(
              delay: const Duration(milliseconds: 100),
              child: _buildCycleIndicator(context, state),
            ),
            const SizedBox(height: 30),
          ],

          // Timer Circle
          Expanded(
            child: Center(
              child: SlideInAnimation(
                child: _buildTimerCircle(context, currentSession, isRunning),
              ),
            ),
          ),

          // Task Input (only when not running)
          if (!isRunning && !isPaused) ...[
            const SizedBox(height: 20),
            FadeInAnimation(
              delay: const Duration(milliseconds: 200),
              child: TextField(
                controller: _taskController,
                decoration: const InputDecoration(
                  hintText: 'What are you working on?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.task_outlined),
                ),
                maxLines: 1,
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Control Buttons
          _buildControlButtons(
              context, state, currentSession, isRunning, isPaused),

          const SizedBox(height: 20),

          // Session Progress Indicator - Removed
        ],
      ),
    );
  }

  Widget _buildTimerCircle(
    BuildContext context,
    PomodoroSession? session,
    bool isRunning,
  ) {
    final size = MediaQuery.of(context).size.width * 0.7;
    final progress = session?.progressPercentage ?? 0.0;
    final timeText =
        session != null ? _formatTime(session.remainingTime) : '25:00';

    return Container(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background Circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),

          // Progress Circle
          AnimatedBuilder(
            animation: isRunning ? _pulseController : _progressController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: CircularProgressPainter(
                  progress: progress,
                  color: session != null
                      ? _getSessionColor(session.type)
                      : Theme.of(context).colorScheme.primary,
                  strokeWidth: 8,
                  isAnimating: isRunning,
                  animationValue: _pulseController.value,
                ),
              );
            },
          ),

          // Time Text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timeText,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w300,
                        fontSize: 48,
                        color: session != null
                            ? _getSessionColor(session.type)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                if (session?.taskDescription != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    session!.taskDescription!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    PomodoroState state,
    PomodoroSession? currentSession,
    bool isRunning,
    bool isPaused,
  ) {
    // Check if current session is a break
    final bool isBreakSession = currentSession != null &&
        (currentSession.type == PomodoroType.shortBreak ||
            currentSession.type == PomodoroType.longBreak);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Button (always available when there's any session active)
        if (isRunning || isPaused) ...[
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: () {
              _showResetConfirmationDialog(context);
            },
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 15),
        ],

        // Stop Button (only when running or paused)
        if (isRunning || isPaused) ...[
          FloatingActionButton(
            heroTag: 'stop',
            onPressed: () {
              context.read<PomodoroBloc>().add(const PomodoroStopRequested());
            },
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            child: const Icon(Icons.stop),
          ),
          const SizedBox(width: 15),
        ],

        // Skip Break Button (only when running or paused and in break session)
        if ((isRunning || isPaused) && isBreakSession) ...[
          FloatingActionButton(
            heroTag: 'skip',
            onPressed: () {
              HapticService.buttonTap();
              context
                  .read<PomodoroBloc>()
                  .add(const PomodoroSkipBreakRequested());
            },
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            child: const Icon(Icons.skip_next),
          ),
          const SizedBox(width: 15),
        ],

        // Main Action Button
        FloatingActionButton.large(
          heroTag: 'main',
          onPressed: () async {
            if (isRunning) {
              context.read<PomodoroBloc>().add(const PomodoroPauseRequested());
            } else if (isPaused) {
              context.read<PomodoroBloc>().add(const PomodoroResumeRequested());
            } else {
              context.read<PomodoroBloc>().add(
                    PomodoroStartRequested(
                      taskDescription: _taskController.text.trim().isEmpty
                          ? null
                          : _taskController.text.trim(),
                    ),
                  );
            }
          },
          backgroundColor: currentSession != null
              ? _getSessionColor(currentSession.type)
              : Theme.of(context).colorScheme.primary,
          child: Icon(
            isRunning ? Icons.pause : Icons.play_arrow,
            size: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCompletedView(
    BuildContext context,
    PomodoroSessionCompleted state,
  ) {
    final wasWork = state.completedSession.type == PomodoroType.work;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SlideInAnimation(
            child: Icon(
              wasWork ? Icons.celebration : Icons.self_improvement,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            wasWork ? 'Focus Complete!' : 'Break Complete!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            wasWork
                ? 'Great work! Time for a break.'
                : 'Break over! Ready for another session?',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SlideInAnimation(
            delay: const Duration(milliseconds: 200),
            begin: const Offset(0, 1),
            child: Column(
              children: [
                FilledButton.icon(
                  onPressed: () {
                    context
                        .read<PomodoroBloc>()
                        .add(const PomodoroStartRequested());
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'Start ${state.nextSessionType == PomodoroType.work ? 'Focus' : 'Break'}',
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    context
                        .read<PomodoroBloc>()
                        .add(const PomodoroNextSessionRequested());
                  },
                  child: const Text('Back to Timer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleIndicator(BuildContext context, PomodoroState state) {
    int completedSessions = 0;
    int totalSessions = 4;
    int currentSession = 1;
    bool isWorkSession = true;

    if (state is PomodoroReady) {
      completedSessions =
          state.completedWorkSessions % state.settings.sessionsUntilLongBreak;
      totalSessions = state.settings.sessionsUntilLongBreak;
      currentSession = completedSessions + 1;
    } else if (state is PomodoroRunning) {
      completedSessions =
          state.completedWorkSessions % state.settings.sessionsUntilLongBreak;
      totalSessions = state.settings.sessionsUntilLongBreak;
      currentSession = completedSessions + 1;
      isWorkSession = state.currentSession.type == PomodoroType.work;
    } else if (state is PomodoroPaused) {
      completedSessions =
          state.completedWorkSessions % state.settings.sessionsUntilLongBreak;
      totalSessions = state.settings.sessionsUntilLongBreak;
      currentSession = completedSessions + 1;
      isWorkSession = state.currentSession.type == PomodoroType.work;
    } else if (state is PomodoroSessionCompleted) {
      completedSessions =
          state.completedWorkSessions % state.settings.sessionsUntilLongBreak;
      totalSessions = state.settings.sessionsUntilLongBreak;
      currentSession = completedSessions + 1;
      isWorkSession = state.nextSessionType == PomodoroType.work;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cycle text
          Text(
            isWorkSession
                ? 'Session $currentSession of $totalSessions'
                : 'Break Time',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 8),
          // Visual indicators
          ...List.generate(totalSessions, (index) {
            final isCompleted = index < completedSessions;
            final isCurrent = index == completedSessions &&
                (state is PomodoroRunning || state is PomodoroPaused);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.orange.shade600
                    : isCurrent
                        ? Colors.orange.shade400
                        : Colors.grey.shade300,
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Reset Pomodoro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will completely reset your current Pomodoro session, including:',
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('• Current timer progress'),
            _buildBulletPoint('• Session count progress'),
            _buildBulletPoint('• Any running timers'),
            _buildBulletPoint('• Saved task description'),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<PomodoroBloc>().add(const PomodoroResetRequested());
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Color _getSessionColor(PomodoroType type) {
    switch (type) {
      case PomodoroType.work:
        return Colors.red.shade400;
      case PomodoroType.shortBreak:
        return Colors.green.shade400;
      case PomodoroType.longBreak:
        return Colors.blue.shade400;
    }
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showBreakPromptDialog(
    BuildContext context,
    PomodoroSessionCompleted state,
  ) {
    final isLongBreak = state.nextSessionType == PomodoroType.longBreak;
    final breakMinutes = isLongBreak
        ? state.settings.longBreakMinutes
        : state.settings.shortBreakMinutes;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.celebration,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Work Session Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Great job! You completed a ${state.completedSession.durationMinutes}-minute focus session.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Time for a ${isLongBreak ? 'long' : 'short'} break ($breakMinutes minutes).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<PomodoroBloc>()
                  .add(const PomodoroNextSessionRequested());
            },
            child: const Text('Skip Break'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<PomodoroBloc>().add(const PomodoroStartRequested());
            },
            icon: const Icon(Icons.self_improvement),
            label: const Text('Start Break'),
          ),
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool isAnimating;
  final double animationValue;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.isAnimating = false,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isAnimating) {
      // Add pulsing effect
      paint.strokeWidth = strokeWidth + (animationValue * 2);
      paint.color = color.withOpacity(0.7 + (animationValue * 0.3));
    }

    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
