import 'package:flutter/material.dart';

class SimpleCircularTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const SimpleCircularTimer({
    super.key,
    required this.duration,
    this.onComplete,
  });

  @override
  State<SimpleCircularTimer> createState() => _SimpleCircularTimerState();
}

class _SimpleCircularTimerState extends State<SimpleCircularTimer>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void start() {
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  void pause() {
    _controller.stop();
  }

  void resume() {
    _controller.forward();
  }

  void reset() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final remaining = widget.duration * (1 - progress);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _formatTime(remaining),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: start,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: pause,
                  child: const Text('Pause'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
