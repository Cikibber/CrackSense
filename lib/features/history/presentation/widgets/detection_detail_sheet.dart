import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/severity_indicator.dart';
import '../../domain/models/detection_record.dart';

/// Bottom sheet displaying full details of a detection record.
class DetectionDetailSheet extends StatelessWidget {
  final DetectionRecord record;

  const DetectionDetailSheet({
    super.key,
    required this.record,
  });

  static void show(BuildContext context, DetectionRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetectionDetailSheet(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Image
              if (record.imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.memory(
                      record.imageBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.xxl),

              // Classification + Confidence
              Row(
                children: [
                  Text('Classification', style: AppTypography.titleMedium),
                  const Spacer(),
                  SeverityIndicator(
                    severity: record.classification,
                    confidence: record.confidence,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Metadata grid
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date & Time',
                      value: DateFormatter.fullDateTime(record.timestamp),
                    ),
                    const Divider(height: AppSpacing.xxl),
                    _DetailRow(
                      icon: Icons.speed_outlined,
                      label: 'Confidence',
                      value: record.confidencePercent,
                    ),
                    if (record.inferenceTimeMs > 0) ...[
                      const Divider(height: AppSpacing.xxl),
                      _DetailRow(
                        icon: Icons.timer_outlined,
                        label: 'Inference Time',
                        value: '${record.inferenceTimeMs}ms',
                      ),
                    ],
                    if (record.altitude != null) ...[
                      const Divider(height: AppSpacing.xxl),
                      _DetailRow(
                        icon: Icons.height_rounded,
                        label: 'Altitude',
                        value: '${record.altitude!.toStringAsFixed(1)}m',
                      ),
                    ],
                    const Divider(height: AppSpacing.xxl),
                    _DetailRow(
                      icon: Icons.fingerprint_rounded,
                      label: 'Record ID',
                      value: record.id.substring(0, 8),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: AppTypography.caption),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
