import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/history_providers.dart';
import '../widgets/history_list_tile.dart';
import '../widgets/detection_detail_sheet.dart';

/// History screen displaying all past crack detection records.
///
/// Features:
/// - Filterable by severity classification
/// - Swipe-to-delete individual records
/// - Tap to view full details in bottom sheet
/// - Empty state with informative messaging
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const _filterOptions = ['All', 'Vertical', 'Horizontal', 'Diagonal'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(selectedFilterProvider);
    final recordsAsync = ref.watch(filteredRecordsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingH,
                AppSpacing.xxl,
                AppSpacing.screenPaddingH,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detection History',
                      style: AppTypography.headlineMedium,
                    ),
                  ),
                  // Record count badge
                  Consumer(
                    builder: (context, ref, _) {
                      final countAsync = ref.watch(recordCountProvider);
                      return countAsync.when(
                        data: (count) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusRound),
                          ),
                          child: Text(
                            '$count records',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Filter Chips ──────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                ),
                itemCount: _filterOptions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final filter = _filterOptions[index];
                  final isAll = filter == 'All';
                  final isSelected = isAll
                      ? selectedFilter == null
                      : selectedFilter == filter;

                  return FilterChip(
                    selected: isSelected,
                    label: Text(filter),
                    labelStyle: AppTypography.labelLarge.copyWith(
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    backgroundColor: AppColors.surfaceVariant,
                    selectedColor: AppColors.primary,
                    checkmarkColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusRound),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    onSelected: (_) {
                      ref.read(selectedFilterProvider.notifier)
                          .set(isAll ? null : filter);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Records List ──────────────────────────────────
            Expanded(
              child: recordsAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingH,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: records.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return HistoryListTile(
                        record: record,
                        onTap: () {
                          DetectionDetailSheet.show(context, record);
                        },
                        onDelete: () async {
                          final repository =
                              ref.read(historyRepositoryProvider);
                          await repository.deleteRecord(record.id);
                          ref.invalidate(filteredRecordsProvider);
                          ref.invalidate(allDetectionRecordsProvider);
                          ref.invalidate(recordCountProvider);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Record deleted'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.severityStructural,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Failed to load records',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        error.toString(),
                        style: AppTypography.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 40,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'No detections yet',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Run an analysis on the Live Feed tab\nto see results here',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
