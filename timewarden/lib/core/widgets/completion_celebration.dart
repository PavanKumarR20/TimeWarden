import 'package:flutter/material.dart';
import 'dart:math' as math;

class CompletionCelebration extends StatefulWidget {
  final Widget child;
  final bool isCompleted;
  final Color color;

  const CompletionCelebration({
    super.key,
    required this.child,
    required this.isCompleted,
    required this.color,
  });

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(CompletionCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isCompleted && widget.isCompleted) {
      _triggerCelebration();
    }
  }

  void _triggerCelebration() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
    _sparkleController.forward().then((_) {
      _sparkleController.reverse();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _sparkleAnimation]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Sparkles
            if (widget.isCompleted) ..._buildSparkles(),

            // Main widget with pulse
            Transform.scale(
              scale: _pulseAnimation.value,
              child: widget.child,
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildSparkles() {
    return List.generate(6, (index) {
      final angle = (index * 60) * math.pi / 180;
      final distance = 20.0 * _sparkleAnimation.value;
      final opacity = (1.0 - _sparkleAnimation.value) * 0.8;

      return Positioned(
        left: math.cos(angle) * distance,
        top: math.sin(angle) * distance,
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: _sparkleAnimation.value,
            child: Icon(
              Icons.star_rounded,
              size: 8,
              color: widget.color.withOpacity(0.8),
            ),
          ),
        ),
      );
    });
  }
}

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.isActive = false,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.transparent,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
