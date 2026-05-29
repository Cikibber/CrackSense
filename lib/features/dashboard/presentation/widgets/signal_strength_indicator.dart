import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';

/// Signal strength indicator with animated Wi-Fi-style bars.
class SignalStrengthIndicator extends StatelessWidget {
  final int strength;

  const SignalStrengthIndicator({
    super.key,
    required this.strength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Vertical bars
        SizedBox(
          width: 60,
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (index) {
              final barHeight = 10.0 + (index * 7.0);
              final isActive = _activeBars > index;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 8,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: isActive ? _barColor : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _barColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$strength%',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: _barColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _qualityLabel,
          style: AppTypography.labelSmall.copyWith(
            color: _barColor,
          ),
        ),
      ],
    );
  }

  int get _activeBars {
    if (strength > 80) return 5;
    if (strength > 60) return 4;
    if (strength > 40) return 3;
    if (strength > 20) return 2;
    if (strength > 0) return 1;
    return 0;
  }

  Color get _barColor {
    if (strength > 60) return AppColors.severitySafe;
    if (strength > 30) return AppColors.severityHairline;
    return AppColors.severityStructural;
  }

  String get _qualityLabel {
    if (strength > 75) return 'Excellent';
    if (strength > 50) return 'Good';
    if (strength > 25) return 'Weak';
    return 'Poor';
  }
}
