import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drone_crack_detection/features/live_feed/domain/models/detection_result.dart';
import 'tflite_service.dart';

/// Provider for the currently selected model path
final selectedModelProvider = NotifierProvider<SelectedModelNotifier, String>(SelectedModelNotifier.new);

class SelectedModelNotifier extends Notifier<String> {
  @override
  String build() => 'assets/models/cracksense_ResNet50.tflite'; // Default model (Model C - ResNet50)

  void setModel(String newModel) {
    state = newModel;
  }
}

/// Singleton provider for the TFLite service.
final tfliteServiceProvider = Provider<TfliteService>((ref) {
  final service = TfliteService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Async provider to initialize the TFLite model.
final tfliteInitProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(tfliteServiceProvider);
  final currentModel = ref.watch(selectedModelProvider);
  
  try {
    await service.changeModel(currentModel);
    return true;
  } catch (e) {
    return false;
  }
});

/// Provider to run inference on a given image.
final classifyImageProvider =
    FutureProvider.family<DetectionResult?, Uint8List>((ref, imageBytes) async {
  final service = ref.watch(tfliteServiceProvider);
  if (!service.isInitialized) {
    try {
      await service.initialize();
    } catch (_) {
      return null;
    }
  }
  return service.classifyImage(imageBytes);
});

/// Notifier to hold the latest detection result for display.
final latestDetectionProvider =
    NotifierProvider<LatestDetectionNotifier, DetectionResult?>(
        LatestDetectionNotifier.new);

class LatestDetectionNotifier extends Notifier<DetectionResult?> {
  @override
  DetectionResult? build() => null;

  void set(DetectionResult? result) => state = result;
}

/// Notifier to track whether inference is currently running.
final isAnalyzingProvider =
    NotifierProvider<IsAnalyzingNotifier, bool>(IsAnalyzingNotifier.new);

class IsAnalyzingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
