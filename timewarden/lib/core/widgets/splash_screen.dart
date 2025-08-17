import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  final Widget child;

  const SplashScreen({
    super.key,
    required this.child,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    // Scale animation with gentle bounce
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Slide animation
    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    // Simple entrance animation
    await _animationController.forward();

    // Brief pause before transition
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.child,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Simple, clean app icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.schedule,
                            size: 50,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // App name - clean and simple
                        Text(
                          'TimeWarden',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),

                        const SizedBox(height: 40),

                        // Simple loading indicator
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final Color color;
  final double time;

  ClockPainter({required this.color, this.time = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Draw clock face outline
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // Draw hour markers
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (math.pi / 180);
      final startX = center.dx + (radius - 8) * math.cos(angle - math.pi / 2);
      final startY = center.dy + (radius - 8) * math.sin(angle - math.pi / 2);
      final endX = center.dx + radius * math.cos(angle - math.pi / 2);
      final endY = center.dy + radius * math.sin(angle - math.pi / 2);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        Paint()
          ..color = color.withOpacity(0.4)
          ..strokeWidth = i % 3 == 0 ? 2 : 1,
      );
    }

    // Draw animated hour hand
    final hourAngle = (time * 360) * (math.pi / 180);
    final hourEndX =
        center.dx + (radius * 0.5) * math.cos(hourAngle - math.pi / 2);
    final hourEndY =
        center.dy + (radius * 0.5) * math.sin(hourAngle - math.pi / 2);
    canvas.drawLine(center, Offset(hourEndX, hourEndY), paint);

    // Draw animated minute hand
    final minuteAngle = (time * 360 * 12) * (math.pi / 180);
    final minuteEndX =
        center.dx + (radius * 0.7) * math.cos(minuteAngle - math.pi / 2);
    final minuteEndY =
        center.dy + (radius * 0.7) * math.sin(minuteAngle - math.pi / 2);
    canvas.drawLine(center, Offset(minuteEndX, minuteEndY), paint);

    // Draw center dot
    canvas.drawCircle(center, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
