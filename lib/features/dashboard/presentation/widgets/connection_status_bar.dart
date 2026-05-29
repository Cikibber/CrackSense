import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';

/// Animated connection status bar at the top of the Dashboard.
/// Shows connected/connecting/disconnected state with smooth transitions.
class ConnectionStatusBar extends StatelessWidget {
  final String statusLabel;
  final bool isConnected;
  final bool isConnecting;
  final bool hasError;
  final VoidCallback? onReconnect;

  const ConnectionStatusBar({
    super.key,
    required this.statusLabel,
    required this.isConnected,
    required this.isConnecting,
    this.hasError = false,
    this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: _borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Drone icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: _iconGlow,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.flight_rounded,
              color: _iconColor,
              size: AppSpacing.iconLg,
            ),
          ),

          const SizedBox(width: AppSpacing.lg),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drone Connection',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                StatusBadge(
                  label: statusLabel,
                  status: _statusType,
                ),
              ],
            ),
          ),

          // Reconnect button (only when disconnected or error)
          if (!isConnected && !isConnecting)
            IconButton(
              onPressed: onReconnect,
              icon: const Icon(Icons.refresh_rounded),
              color: AppColors.accent,
              tooltip: 'Reconnect',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
              ),
            ),

          // Spinning indicator when connecting
          if (isConnecting)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.connecting,
              ),
            ),
        ],
      ),
    );
  }

  StatusType get _statusType {
    if (isConnected) return StatusType.connected;
    if (isConnecting) return StatusType.connecting;
    if (hasError) return StatusType.error;
    return StatusType.disconnected;
  }

  Color get _backgroundColor {
    if (isConnected) return AppColors.connected.withValues(alpha: 0.05);
    if (isConnecting) return AppColors.connecting.withValues(alpha: 0.05);
    return AppColors.disconnected.withValues(alpha: 0.05);
  }

  Color get _borderColor {
    if (isConnected) return AppColors.connected.withValues(alpha: 0.15);
    if (isConnecting) return AppColors.connecting.withValues(alpha: 0.15);
    return AppColors.disconnected.withValues(alpha: 0.15);
  }

  Color get _iconColor {
    if (isConnected) return AppColors.connected;
    if (isConnecting) return AppColors.connecting;
    return AppColors.disconnected;
  }

  Color get _iconGlow {
    if (isConnected) return AppColors.connected.withValues(alpha: 0.15);
    if (isConnecting) return AppColors.connecting.withValues(alpha: 0.15);
    return AppColors.disconnected.withValues(alpha: 0.1);
  }
}
