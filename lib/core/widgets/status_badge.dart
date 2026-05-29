import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_spacing.dart';

/// Connection status badge with animated color transitions.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType status;

  const StatusBadge({
    super.key,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        border: Border.all(
          color: _borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: _textColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    if (status == StatusType.connecting) {
      return SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _dotColor,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _dotColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _dotColor.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Color get _dotColor {
    switch (status) {
      case StatusType.connected:
        return AppColors.connected;
      case StatusType.connecting:
        return AppColors.connecting;
      case StatusType.disconnected:
      case StatusType.error:
        return AppColors.disconnected;
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case StatusType.connected:
        return AppColors.connected.withValues(alpha: 0.08);
      case StatusType.connecting:
        return AppColors.connecting.withValues(alpha: 0.08);
      case StatusType.disconnected:
      case StatusType.error:
        return AppColors.disconnected.withValues(alpha: 0.08);
    }
  }

  Color get _borderColor {
    return _dotColor.withValues(alpha: 0.2);
  }

  Color get _textColor {
    switch (status) {
      case StatusType.connected:
        return AppColors.connected;
      case StatusType.connecting:
        return AppColors.connecting;
      case StatusType.disconnected:
      case StatusType.error:
        return AppColors.disconnected;
    }
  }
}

enum StatusType { connected, connecting, disconnected, error }
