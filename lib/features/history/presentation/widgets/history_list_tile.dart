import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/severity_indicator.dart';
import '../../domain/models/detection_record.dart';

/// List tile for a single detection history entry.
/// Shows thumbnail, classification badge, timestamp, and confidence.
class HistoryListTile extends StatelessWidget {
  final DetectionRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const HistoryListTile({
    super.key,
    required this.record,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.severityStructural.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.severityStructural,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  width: 60,
                  height: 60,
                  color: AppColors.surfaceVariant,
                  child: record.imageBytes != null
                      ? Image.memory(
                          record.imageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),

              const SizedBox(width: AppSpacing.lg),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SeverityIndicator(
                          severity: record.classification,
                          compact: true,
                        ),
                        const Spacer(),
                        Text(
                          record.confidencePercent,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      DateFormatter.relative(record.timestamp),
                      style: AppTypography.caption,
                    ),
                    if (record.altitude != null)
                      Text(
                        'Altitude: ${record.altitude!.toStringAsFixed(1)}m',
                        style: AppTypography.labelSmall,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Chevron
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textTertiary,
        size: 24,
      ),
    );
  }
}
