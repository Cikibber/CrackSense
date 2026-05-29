import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';

/// Displays the incoming drone camera feed image.
/// Shows a placeholder state when no frame has been received yet.
class CameraFeedView extends StatelessWidget {
  final ImageProvider? imageProvider;
  final bool isConnected;

  const CameraFeedView({
    super.key,
    this.imageProvider,
    this.isConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (imageProvider != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Image(
          image: imageProvider!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isConnected
                  ? Icons.videocam_rounded
                  : Icons.videocam_off_rounded,
              color: isConnected
                  ? AppColors.primary
                  : AppColors.textTertiary,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isConnected
                ? 'Waiting for camera feed...'
                : 'No drone connected',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isConnected
                ? 'The drone camera feed will appear here'
                : 'Connect to a drone to view the live feed',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
