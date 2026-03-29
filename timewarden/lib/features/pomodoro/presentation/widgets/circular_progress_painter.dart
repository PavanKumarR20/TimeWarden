import 'dart:math';
import 'package:flutter/material.dart';

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

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Add animation effect if running
      if (isAnimating) {
        progressPaint.color = color.withOpacity(0.7 + (animationValue * 0.3));
      }

      const startAngle = -pi / 2; // Start from top
      final sweepAngle = 2 * pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isAnimating != isAnimating ||
        oldDelegate.animationValue != animationValue;
  }
}
