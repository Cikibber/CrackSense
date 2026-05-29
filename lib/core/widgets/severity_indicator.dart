import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_spacing.dart';

/// Displays a severity level badge with color-coded background and text label.
/// Always includes both color AND text for accessibility (not color-only).
class SeverityIndicator extends StatelessWidget {
  final String severity;
  final double? confidence;
  final bool compact;

  const SeverityIndicator({
    super.key,
    required this.severity,
    this.confidence,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(severity);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: compact ? 12 : 16,
            color: config.color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            severity,
            style: (compact ? AppTypography.labelSmall : AppTypography.labelLarge).copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (confidence != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${(confidence! * 100).toStringAsFixed(1)}%',
              style: AppTypography.labelSmall.copyWith(
                color: config.color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _SeverityConfig _getConfig(String severity) {
    switch (severity.toLowerCase()) {
      case 'vertical':
        return _SeverityConfig(
          color: AppColors.severityHairline,
          backgroundColor: AppColors.severityHairlineBg,
          icon: Icons.swap_vert_rounded,
        );
      case 'horizontal':
        return _SeverityConfig(
          color: AppColors.severityStructural,
          backgroundColor: AppColors.severityStructuralBg,
          icon: Icons.swap_horiz_rounded,
        );
      case 'diagonal':
        return _SeverityConfig(
          color: AppColors.severitySpalling,
          backgroundColor: AppColors.severitySpallingBg,
          icon: Icons.open_in_full_rounded,
        );
      default:
        return _SeverityConfig(
          color: AppColors.textSecondary,
          backgroundColor: AppColors.surfaceVariant,
          icon: Icons.help_outline_rounded,
        );
    }
  }
}

class _SeverityConfig {
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  const _SeverityConfig({
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });
}
