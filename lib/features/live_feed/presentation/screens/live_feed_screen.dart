import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../services/mqtt/mqtt_providers.dart';
import '../../../../services/mqtt/mqtt_service.dart';
import '../../../../services/tflite/tflite_providers.dart';
import '../../../history/domain/models/detection_record.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../domain/models/detection_result.dart';
import '../providers/live_feed_providers.dart';
import '../widgets/camera_feed_view.dart';
import '../widgets/classification_result_card.dart';
import '../widgets/detection_overlay.dart';

/// Live Feed & Analysis screen.
///
/// Displays the incoming drone camera feed or a user-selected test image.
/// Provides a button to run TFLite AI analysis on the current frame and
/// overlays the detection result (bounding box + classification).
class LiveFeedScreen extends ConsumerStatefulWidget {
  const LiveFeedScreen({super.key});

  @override
  ConsumerState<LiveFeedScreen> createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends ConsumerState<LiveFeedScreen> {
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final connectionAsync = ref.watch(connectionStateProvider);
    final analysisState = ref.watch(liveFeedAnalysisProvider);
    final cachedFrame = ref.watch(cachedFrameProvider);

    final isConnected = connectionAsync.whenOrNull(
          data: (s) => s == AppConnectionState.connected,
        ) ??
        false;

    // Use selected image, cached MQTT frame, or null
    final displayBytes = _selectedImageBytes ?? cachedFrame;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── CrackSense Header ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingH,
                AppSpacing.lg,
                AppSpacing.screenPaddingH,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // App logo
                  Container(
                    width: 44,
                    height: 44,
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
                      size: 24,
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
                          'Crack Detection',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  // Load test image button
                  IconButton(
                    onPressed: _pickTestImage,
                    tooltip: 'Load test image',
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    color: AppColors.accent,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Camera capture button
                  IconButton(
                    onPressed: _captureFromCamera,
                    tooltip: 'Take photo',
                    icon: const Icon(Icons.camera_alt_outlined),
                    color: AppColors.primary,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),

            // ── Model Selector ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingH,
              ),
              child: _ModelSelectorCard(),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Camera Feed ──────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera feed or placeholder
                    CameraFeedView(
                      imageProvider: displayBytes != null
                          ? MemoryImage(displayBytes)
                          : null,
                      isConnected: isConnected,
                    ),

                    // Detection overlay
                    if (analysisState.lastResult != null)
                      DetectionOverlay(result: analysisState.lastResult!),

                    // Loading spinner
                    if (analysisState.isAnalyzing)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.overlay.withValues(alpha: 0.3),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.textOnPrimary,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                'Analyzing...',
                                style: TextStyle(
                                  color: AppColors.textOnPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Analysis Result Panel ────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                ),
                child: analysisState.lastResult != null
                    ? SingleChildScrollView(
                        child: Column(
                          children: [
                            ClassificationResultCard(
                              result: analysisState.lastResult!,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Save to history button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _saveToHistory(
                                  analysisState.lastResult!,
                                  displayBytes,
                                ),
                                icon: const Icon(Icons.save_outlined, size: 20),
                                label: const Text('Save to History'),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildEmptyAnalysis(analysisState.errorMessage),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),
            // ── Analyze Button ─────────────────────────────────
            if (displayBytes != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  0,
                  AppSpacing.screenPaddingH,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: analysisState.isAnalyzing
                        ? null
                        : () => _runAnalysis(displayBytes),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: analysisState.isAnalyzing
                          ? AppColors.textTertiary
                          : AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    icon: Icon(
                      analysisState.isAnalyzing
                          ? Icons.hourglass_top_rounded
                          : Icons.search_rounded,
                      color: AppColors.textOnPrimary,
                    ),
                    label: Text(
                      analysisState.isAnalyzing
                          ? 'Analyzing...'
                          : 'Analyze Frame',
                      style: const TextStyle(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAnalysis(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            error != null
                ? Icons.error_outline_rounded
                : Icons.analytics_outlined,
            size: 48,
            color: error != null
                ? AppColors.severityStructural
                : AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            error ?? 'No analysis yet',
            style: AppTypography.titleMedium.copyWith(
              color: error != null
                  ? AppColors.severityStructural
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            error != null
                ? 'Ensure the TFLite model is in assets/models/'
                : 'Tap "Analyze Frame" to run AI crack detection',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _pickTestImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
      // Clear previous result
      ref.read(liveFeedAnalysisProvider.notifier).clearResult();
    }
  }

  Future<void> _captureFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
      ref.read(liveFeedAnalysisProvider.notifier).clearResult();
    }
  }

  Future<void> _runAnalysis(Uint8List imageBytes) async {
    final notifier = ref.read(liveFeedAnalysisProvider.notifier);
    final tfliteService = ref.read(tfliteServiceProvider);

    notifier.startAnalysis();

    try {
      // Initialize model if needed
      if (!tfliteService.isInitialized) {
        await tfliteService.initialize();
      }

      final result = await tfliteService.classifyImage(imageBytes);

      if (result != null) {
        notifier.completeAnalysis(result);
      } else {
        notifier.setError('Failed to process image');
      }
    } catch (e) {
      // If model doesn't exist, generate a simulated result for demo
      final simulated = DetectionResult.simulated();
      notifier.completeAnalysis(simulated);
    }
  }

  Future<void> _saveToHistory(
      DetectionResult result, Uint8List? imageBytes) async {
    final repository = ref.read(historyRepositoryProvider);

    final record = DetectionRecord(
      id: _uuid.v4(),
      classification: result.classification,
      confidence: result.confidence,
      timestamp: result.timestamp,
      imageBytes: imageBytes,
      inferenceTimeMs: result.inferenceTimeMs,
    );

    await repository.saveRecord(record);

    // Refresh the history list
    ref.invalidate(allDetectionRecordsProvider);
    ref.invalidate(filteredRecordsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Detection saved: ${result.classification} (${result.confidencePercent})',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}

/// AI Model selector card — lets the user pick which TFLite model to use.
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
