import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../services/mqtt/mqtt_providers.dart';
import '../../../../services/tflite/tflite_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/telemetry_panel.dart';

/// Main Dashboard screen — the app's control center.
///
/// Displays:
/// - MQTT connection status with reconnect action
/// - Real-time telemetry grid (battery, signal, altitude)
/// - Drone status and last-updated timestamp
/// - Quick action buttons for scanning and history
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Connect to MQTT on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mqttServiceProvider).connect();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionDisplay = ref.watch(connectionDisplayProvider);
    final telemetry = ref.watch(cachedTelemetryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.read(mqttServiceProvider).disconnect();
              await Future.delayed(const Duration(milliseconds: 300));
              ref.read(mqttServiceProvider).connect();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // ── App Bar ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPaddingH,
                      AppSpacing.xxl,
                      AppSpacing.screenPaddingH,
                      AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        // App logo
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(
                            Icons.radar_rounded,
                            color: AppColors.textOnPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CrackSense',
                                style: AppTypography.headlineMedium,
                              ),
                              Text(
                                'Drone Inspection System',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        // Notification bell
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.textSecondary,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Connection Status ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingH,
                    ),
                    child: ConnectionStatusBar(
                      statusLabel: connectionDisplay.label,
                      isConnected: connectionDisplay.isConnected,
                      isConnecting: connectionDisplay.isConnecting,
                      hasError: connectionDisplay.hasError,
                      onReconnect: () {
                        ref.read(mqttServiceProvider).connect();
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),

                // ── Model Selection ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingH,
                    ),
                    child: _ModelSelectorCard(),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),

                // ── Section: Telemetry ───────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingH,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Live Telemetry',
                          style: AppTypography.headlineSmall,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: connectionDisplay.isConnected
                                ? AppColors.severitySafeBg
                                : AppColors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusRound),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: connectionDisplay.isConnected
                                    ? AppColors.severitySafe
                                    : AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                connectionDisplay.isConnected
                                    ? 'LIVE'
                                    : 'CACHED',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: connectionDisplay.isConnected
                                      ? AppColors.severitySafe
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),

                // ── Telemetry Cards Grid ─────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingH,
                    ),
                    child: TelemetryPanel(telemetry: telemetry),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),

                // ── Drone Status Card ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingH,
                    ),
                    child: GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: const Icon(
                              Icons.flight_takeoff_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Drone Status',
                                  style: AppTypography.caption,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  telemetry.status.displayName,
                                  style: AppTypography.titleLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusRound),
                            ),
                            child: Text(
                              telemetry.batteryLabel,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Quick Actions ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingH,
                    ),
                    child: Text(
                      'Quick Actions',
                      style: AppTypography.headlineSmall,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingH,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.document_scanner_rounded,
                            label: 'Start Scan',
                            subtitle: 'Analyze walls',
                            color: AppColors.primary,
                            onTap: () {
                              // Navigate to live feed tab
                              _navigateToTab(context, 1);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.history_rounded,
                            label: 'History',
                            subtitle: 'Past detections',
                            color: AppColors.accent,
                            onTap: () {
                              _navigateToTab(context, 2);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.huge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, int index) {
    // Use the shell navigation to switch tabs
    final bottomNav = context.findAncestorWidgetOfExactType<Scaffold>();
    if (bottomNav != null) {
      // We'll handle this via the router
    }
  }
}

/// Quick action button widget with icon, label, and gradient hover effect.
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelSelectorCard extends ConsumerWidget {
  const _ModelSelectorCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModel = ref.watch(selectedModelProvider);
    final isInitializing = ref.watch(tfliteInitProvider).isLoading;

    final models = {
      'assets/models/best_BYOL_model_float32.tflite': 'Model A - BYOL',
      'assets/models/best_baseline_model_float32.tflite': 'Model B - Baseline',
      'assets/models/cracksense_ResNet50.tflite': 'Model C - ResNet50',
    };

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.memory_rounded,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active AI Model',
                  style: AppTypography.caption,
                ),
                if (isInitializing)
                  Text(
                    'Loading model...',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedModel,
                      isExpanded: true,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      dropdownColor: AppColors.surface,
                      items: models.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          ref.read(selectedModelProvider.notifier).setModel(newValue);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
