import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/severity_indicator.dart';
import '../../domain/models/detection_result.dart';

/// Card showing detailed classification results with per-class confidence bars.
class ClassificationResultCard extends StatelessWidget {
  final DetectionResult result;

  const ClassificationResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Analysis Result',
                style: AppTypography.titleMedium,
              ),
              const Spacer(),
              SeverityIndicator(
                severity: result.classification,
                compact: true,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Per-class confidence bars
          ...List.generate(result.allLabels.length, (index) {
            final label = result.allLabels[index];
            final confidence = index < result.allConfidences.length
                ? result.allConfidences[index]
                : 0.0;
            final isTop = label == result.classification;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ConfidenceBar(
                label: label,
                confidence: confidence,
                isTop: isTop,
              ),
            );
          }),

          const Divider(height: AppSpacing.xxl),

          // Metadata row
          Row(
            children: [
              _MetaItem(
                icon: Icons.timer_outlined,
                label: '${result.inferenceTimeMs}ms',
              ),
              const SizedBox(width: AppSpacing.xxl),
              _MetaItem(
                icon: Icons.precision_manufacturing_outlined,
                label: result.confidencePercent,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(height: AppSpacing.xxl),

          // Cause and Treatment
          _InfoSection(
            title: 'Penyebab',
            content: result.cause,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoSection(
            title: 'Penanganan',
            content: result.treatment,
            icon: Icons.build_circle_outlined,
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final String label;
  final double confidence;
  final bool isTop;

  const _ConfidenceBar({
    required this.label,
    required this.confidence,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isTop ? FontWeight.w600 : FontWeight.w400,
                color: isTop ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${(confidence * 100).toStringAsFixed(1)}%',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: isTop ? FontWeight.w700 : FontWeight.w400,
                color: isTop ? _barColor : AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: isTop ? 8 : 4,
            backgroundColor: AppColors.divider.withValues(alpha: 0.3),
            color: isTop ? _barColor : AppColors.textTertiary.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Color get _barColor {
    switch (label.toLowerCase()) {
      case 'vertical':
        return AppColors.severityHairline;
      case 'horizontal':
        return AppColors.severityStructural;
      case 'diagonal':
        return AppColors.severitySpalling;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _InfoSection({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          content,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
