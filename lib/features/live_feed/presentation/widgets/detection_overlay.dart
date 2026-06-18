import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/severity_indicator.dart';
import '../../domain/models/detection_result.dart';

/// Overlay widget that paints detection bounding box and classification on the image.
class DetectionOverlay extends StatelessWidget {
  final DetectionResult result;

  const DetectionOverlay({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bounding box overlay (simulated as a central region)
        if (result.hasCrack)
          Positioned(
            left: 40,
            top: 60,
            right: 40,
            bottom: 100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _borderColor,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top-left classification label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    child: Text(
                      '${result.classification} · ${result.confidencePercent}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bottom result card
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: _ResultInfoBar(result: result),
        ),
      ],
    );
  }

  Color get _borderColor {
    switch (result.classification.toLowerCase()) {
      case 'vertical':
      case 'vertikal':
        return AppColors.classVertikal;
      case 'horizontal':
        return AppColors.classHorizontal;
      case 'diagonal':
        return AppColors.classDiagonal;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _ResultInfoBar extends StatelessWidget {
  final DetectionResult result;

  const _ResultInfoBar({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SeverityIndicator(
            severity: result.classification,
            confidence: result.confidence,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.inferenceTimeMs}ms',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                'inference time',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
