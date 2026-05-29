import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/telemetry_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/domain/models/drone_telemetry.dart';
import 'battery_gauge.dart';
import 'signal_strength_indicator.dart';
import 'altitude_display.dart';

/// Container widget that arranges all three telemetry cards in a responsive grid.
class TelemetryPanel extends StatelessWidget {
  final DroneTelemetry telemetry;

  const TelemetryPanel({
    super.key,
    required this.telemetry,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use 2-column grid on narrow screens, 3-column on wide
        final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
        final childAspectRatio = constraints.maxWidth > 500 ? 0.95 : 0.85;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: childAspectRatio,
          children: [
            // Battery Card
            TelemetryCard(
              icon: Icons.battery_charging_full_rounded,
              iconColor: _batteryColor,
              label: 'Battery',
              value: '${telemetry.batteryPercent}',
              customContent: Center(
                child: BatteryGauge(
                  percent: telemetry.batteryPercent,
                  size: 90,
                ),
              ),
            ),

            // Signal Card
            TelemetryCard(
              icon: Icons.signal_cellular_alt_rounded,
              iconColor: _signalColor,
              label: 'Signal',
              value: '${telemetry.signalStrength}',
              customContent: Center(
                child: SignalStrengthIndicator(
                  strength: telemetry.signalStrength,
                ),
              ),
            ),

            // Altitude Card
            TelemetryCard(
              icon: Icons.height_rounded,
              iconColor: AppColors.accent,
              label: 'Altitude',
              value: telemetry.altitudeMeters.toStringAsFixed(1),
              customContent: Center(
                child: AltitudeDisplay(
                  altitude: telemetry.altitudeMeters,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color get _batteryColor {
    if (telemetry.batteryPercent > 60) return AppColors.severitySafe;
    if (telemetry.batteryPercent > 30) return AppColors.severityHairline;
    return AppColors.severityStructural;
  }

  Color get _signalColor {
    if (telemetry.signalStrength > 60) return AppColors.severitySafe;
    if (telemetry.signalStrength > 30) return AppColors.severityHairline;
    return AppColors.severityStructural;
  }
}
