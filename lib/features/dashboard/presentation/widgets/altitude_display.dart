import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';

/// Large numeric altitude display with unit label and altitude zone indicator.
class AltitudeDisplay extends StatelessWidget {
  final double altitude;

  const AltitudeDisplay({
    super.key,
    required this.altitude,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Altitude icon with zone color
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _zoneColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.height_rounded,
            color: _zoneColor,
            size: 24,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Numeric value
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Text(
            altitude.toStringAsFixed(1),
            key: ValueKey(altitude.toStringAsFixed(1)),
            style: AppTypography.telemetryValue.copyWith(
              fontSize: 28,
            ),
          ),
        ),
        Text(
          'meters',
          style: AppTypography.telemetryUnit,
        ),
        const SizedBox(height: AppSpacing.xs),
        // Zone label
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: _zoneColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
          ),
          child: Text(
            _zoneLabel,
            style: AppTypography.labelSmall.copyWith(
              color: _zoneColor,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Color get _zoneColor {
    if (altitude < 10) return AppColors.severitySafe;
    if (altitude < 30) return AppColors.accent;
    if (altitude < 60) return AppColors.severityHairline;
    return AppColors.severityStructural;
  }

  String get _zoneLabel {
    if (altitude < 10) return 'LOW ALTITUDE';
    if (altitude < 30) return 'MID ALTITUDE';
    if (altitude < 60) return 'HIGH ALTITUDE';
    return 'MAX ALTITUDE';
  }
}
