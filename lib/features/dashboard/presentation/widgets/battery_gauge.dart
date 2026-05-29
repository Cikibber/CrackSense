import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// Circular battery gauge widget with animated fill and color transitions.
/// Changes from green → amber → red as battery drains.
class BatteryGauge extends StatelessWidget {
  final int percent;
  final double size;

  const BatteryGauge({
    super.key,
    required this.percent,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BatteryGaugePainter(
          percent: percent,
          color: _gaugeColor,
          trackColor: AppColors.divider.withValues(alpha: 0.3),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _batteryIcon,
                color: _gaugeColor,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                '$percent%',
                style: AppTypography.titleLarge.copyWith(
                  color: _gaugeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _gaugeColor {
    if (percent > 60) return AppColors.severitySafe;
    if (percent > 30) return AppColors.severityHairline;
    return AppColors.severityStructural;
  }

  IconData get _batteryIcon {
    if (percent > 80) return Icons.battery_full_rounded;
    if (percent > 60) return Icons.battery_5_bar_rounded;
    if (percent > 40) return Icons.battery_4_bar_rounded;
    if (percent > 20) return Icons.battery_2_bar_rounded;
    return Icons.battery_alert_rounded;
  }
}

class _BatteryGaugePainter extends CustomPainter {
  final int percent;
  final Color color;
  final Color trackColor;

  _BatteryGaugePainter({
    required this.percent,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    const strokeWidth = 8.0;

    // Track (background arc)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percent / 100) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      sweepAngle,
      false,
      valuePaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryGaugePainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.color != color;
  }
}
