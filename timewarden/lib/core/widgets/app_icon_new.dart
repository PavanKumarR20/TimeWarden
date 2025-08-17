import 'package:flutter/material.dart';
import 'dart:math' as math;

class AppIconPainter extends CustomPainter {
  final Color primaryColor;
  final Color backgroundColor;
  final Color accentColor;

  AppIconPainter({
    required this.primaryColor,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Modern background with gradient
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor,
        primaryColor.withOpacity(0.8),
      ],
    );

    final bgPaint = Paint()..shader = gradient.createShader(rect);
    final roundedRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(roundedRect, bgPaint);

    final center = Offset(size.width / 2, size.height / 2);
    final clockRadius = size.width * 0.28;

    // Clock face
    final clockBgPaint = Paint()
      ..color = backgroundColor.withOpacity(0.95)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, clockRadius, clockBgPaint);

    // Clock border
    final borderPaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.015;
    canvas.drawCircle(center, clockRadius, borderPaint);

    // Hour markers (12, 3, 6, 9)
    final markerPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = size.width * 0.02
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = (i * 90) * (math.pi / 180);
      final markerStart = center +
          Offset(
            (clockRadius - size.width * 0.06) * math.cos(angle - math.pi / 2),
            (clockRadius - size.width * 0.06) * math.sin(angle - math.pi / 2),
          );
      final markerEnd = center +
          Offset(
            (clockRadius - size.width * 0.02) * math.cos(angle - math.pi / 2),
            (clockRadius - size.width * 0.02) * math.sin(angle - math.pi / 2),
          );
      canvas.drawLine(markerStart, markerEnd, markerPaint);
    }

    // Clock hands - 2:25 (Pomodoro time)
    final handPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = size.width * 0.015
      ..strokeCap = StrokeCap.round;

    // Hour hand
    final hourAngle = (2.5 * 30) * (math.pi / 180); // 2:30
    final hourEnd = center +
        Offset(
          (clockRadius * 0.5) * math.cos(hourAngle - math.pi / 2),
          (clockRadius * 0.5) * math.sin(hourAngle - math.pi / 2),
        );
    canvas.drawLine(center, hourEnd, handPaint);

    // Minute hand
    final minuteAngle = (25 * 6) * (math.pi / 180); // 25 minutes
    final minuteEnd = center +
        Offset(
          (clockRadius * 0.7) * math.cos(minuteAngle - math.pi / 2),
          (clockRadius * 0.7) * math.sin(minuteAngle - math.pi / 2),
        );
    canvas.drawLine(center, minuteEnd, handPaint);

    // Center dot
    final centerDotPaint = Paint()..color = primaryColor;
    canvas.drawCircle(center, size.width * 0.02, centerDotPaint);

    // Pomodoro indicators at corners
    final dotRadius = size.width * 0.025;
    final positions = [
      Offset(size.width * 0.25, size.height * 0.2),
      Offset(size.width * 0.75, size.height * 0.2),
      Offset(size.width * 0.25, size.height * 0.8),
      Offset(size.width * 0.75, size.height * 0.8),
    ];

    for (int i = 0; i < 4; i++) {
      final dotPaint = Paint()
        ..color = i < 2 ? accentColor : accentColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(positions[i], dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class AppIconWidget extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color backgroundColor;
  final Color accentColor;

  const AppIconWidget({
    super.key,
    required this.size,
    required this.primaryColor,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: AppIconPainter(
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

// Helper class for different icon variants
class IconVariants {
  // Original blue theme
  static Widget primary(double size) => AppIconWidget(
        size: size,
        primaryColor: const Color(0xFF1976D2), // Blue
        backgroundColor: Colors.white,
        accentColor: const Color(0xFFFF6B35), // Orange
      );

  // Dark theme
  static Widget dark(double size) => AppIconWidget(
        size: size,
        primaryColor: const Color(0xFF90CAF9), // Light blue
        backgroundColor: const Color(0xFF121212), // Dark
        accentColor: const Color(0xFFFF8A50), // Light orange
      );

  // Green productivity theme
  static Widget green(double size) => AppIconWidget(
        size: size,
        primaryColor: const Color(0xFF2E7D32), // Dark green
        backgroundColor: Colors.white,
        accentColor: const Color(0xFF66BB6A), // Light green
      );

  // Purple modern theme
  static Widget purple(double size) => AppIconWidget(
        size: size,
        primaryColor: const Color(0xFF7B1FA2), // Purple
        backgroundColor: Colors.white,
        accentColor: const Color(0xFFBA68C8), // Light purple
      );

  // Orange warm theme
  static Widget orange(double size) => AppIconWidget(
        size: size,
        primaryColor: const Color(0xFFE65100), // Dark orange
        backgroundColor: Colors.white,
        accentColor: const Color(0xFFFFB74D), // Light orange
      );

  // Teal professional theme
  static Widget teal(double size) => AppIconWidget(
        size: size,
        primaryColor: const Color(0xFF00695C), // Dark teal
        backgroundColor: Colors.white,
        accentColor: const Color(0xFF4DB6AC), // Light teal
      );

  // Red energy theme
  static Widget red(double size) => AppIconWidget(
        size: size,
        primaryColor: const Color(0xFFC62828), // Dark red
        backgroundColor: Colors.white,
        accentColor: const Color(0xFFEF5350), // Light red
      );

  // Minimal black & white
  static Widget minimal(double size) => AppIconWidget(
        size: size,
        primaryColor: const Color(0xFF212121), // Dark gray
        backgroundColor: Colors.white,
        accentColor: const Color(0xFF757575), // Medium gray
      );

  // Deep blue elegant
  static Widget deepBlue(double size) => AppIconWidget(
        size: size,
        primaryColor: const Color(0xFF1A237E), // Deep blue
        backgroundColor: Colors.white,
        accentColor: const Color(0xFF3F51B5), // Indigo
      );

  // Material design
  static Widget material(double size) => AppIconWidget(
        size: size,
        primaryColor: const Color(0xFF3F51B5), // Indigo
        backgroundColor: Colors.white,
        accentColor: const Color(0xFFE91E63), // Pink
      );

  // Adaptive (follows system theme)
  static Widget adaptive(BuildContext context, double size) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark(size) : primary(size);
  }
}
