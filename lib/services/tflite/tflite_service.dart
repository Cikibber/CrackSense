import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/utils/image_utils.dart';
import '../../features/live_feed/domain/models/detection_result.dart';

/// Service for running on-device crack detection inference using TensorFlow Lite.
///
/// Handles:
/// - Loading the .tflite model from app assets
/// - Loading label definitions
/// - Image preprocessing (decode → float32 resize → normalize/mean-subtract)
/// - Running inference and returning structured DetectionResult
/// - Resource cleanup
class TfliteService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  // ── Model Configuration ──────────────────────────────────────────
  String _currentModelPath = 'assets/models/cracksense_ResNet50.tflite';
  static const String labelsPath = 'assets/models/labels.txt';
  static const int inputWidth = 224;
  static const int inputHeight = 224;
  static const int inputChannels = 3;
  static const int numClasses = 3;

  /// Whether the model has been successfully loaded.
  bool get isInitialized => _isInitialized;

  /// Available classification labels.
  List<String> get labels => List.unmodifiable(_labels);

  /// Preprocessing mode based on the active model.
  ///
  /// - Model C (ResNet50): BGR mean subtraction (trained with `resnet.preprocess_input`)
  /// - Model A (BYOL) & Model B (Baseline): standard [0,1] normalization
  ///
  /// All models benefit from float32 bilinear resize (no uint8 rounding).
  PreprocessMode get _preprocessMode {
    if (_currentModelPath.contains('ResNet50')) {
      return PreprocessMode.resnet50;
    }
    return PreprocessMode.standard;
  }

  /// Whether the current model already includes softmax in its output layer.
  ///
  /// - Model C (ResNet50): has `Dense(n, activation='softmax')` → output is
  ///   already probabilities, skip softmax
  /// - Model A (BYOL) & B (Baseline): output raw logits → apply softmax
  bool get _modelHasSoftmax {
    return _currentModelPath.contains('ResNet50');
  }

  /// Initializes the TFLite interpreter and loads labels.
  ///
  /// Must be called once before [classifyImage]. Configures the interpreter
  /// with optimized settings for Android (XNNPACK delegate for CPU acceleration).
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load labels
      _labels = await _loadLabels();

      // Configure interpreter options for Android
      final options = InterpreterOptions()..threads = 4;

      // Load model from assets
      _interpreter = await Interpreter.fromAsset(
        _currentModelPath,
        options: options,
      );

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  /// Change the currently active model and reinitialize the interpreter.
  Future<void> changeModel(String newModelPath) async {
    if (_currentModelPath == newModelPath && _isInitialized) {
      return;
    }
    
    // Dispose the old interpreter
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    
    _currentModelPath = newModelPath;
    await initialize();
  }

  /// Runs crack detection inference on the provided JPEG image bytes.
  ///
  /// Returns a [DetectionResult] containing the predicted class, confidence,
  /// and inference timing. Returns null if the model is not initialized or
  /// if preprocessing fails.
  Future<DetectionResult?> classifyImage(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      return null;
    }

    final stopwatch = Stopwatch()..start();

    // ── Step 1: Preprocess with Test-Time Augmentation ────────────
    // Matches the notebook's `tflite_predict_with_tta`: a simple resize to
    // 224×224 then 4 orientation variants (original, flip-LR, flip-UD, rot90),
    // each normalized for the active model:
    // - ResNet50: BGR mean subtraction (output already softmax)
    // - Standard: [0,1] normalization (output logits → softmax per variant)
    final variants = ImageUtils.preprocessVariantsForTTA(
      imageBytes,
      inputWidth: inputWidth,
      inputHeight: inputHeight,
      mode: _preprocessMode,
    );

    if (variants == null || variants.isEmpty) {
      return null;
    }

    // ── Step 2: Run inference on each variant and average probabilities ──
    // Averaging the 4 per-variant probability vectors is what softens an
    // over-confident single pass (~100%) into the notebook's distribution
    // (e.g. 75% / 25% / 0%).
    final List<double> probabilities = List.filled(numClasses, 0.0);

    for (final preprocessed in variants) {
      final input =
          preprocessed.reshape([1, inputHeight, inputWidth, inputChannels]);
      final output = List.generate(1, (_) => List.filled(numClasses, 0.0));
      _interpreter!.run(input, output);

      final rawOutput = output[0];
      // ResNet50 already applies softmax in its output layer — use directly.
      // Logit models (BYOL/Baseline) get softmax applied per variant.
      final List<double> variantProbs =
          _modelHasSoftmax ? rawOutput : _softmax(rawOutput);
      for (int i = 0; i < numClasses; i++) {
        probabilities[i] += variantProbs[i];
      }
    }

    // Average over the variants.
    for (int i = 0; i < numClasses; i++) {
      probabilities[i] /= variants.length;
    }

    stopwatch.stop();

    // ── DEBUG: Log averaged probabilities ─────────────────────────
    debugPrint('[TFLite DEBUG] Model: $_currentModelPath');
    debugPrint('[TFLite DEBUG] TTA variants: ${variants.length}');
    debugPrint('[TFLite DEBUG] Averaged probabilities: $probabilities');

    // ── Step 3: Find the class with highest confidence ────────────
    int maxIndex = 0;
    double maxConfidence = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        maxIndex = i;
      }
    }

    final classification =
        maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';

    return DetectionResult(
      classification: classification,
      confidence: maxConfidence,
      allConfidences: probabilities,
      allLabels: List.from(_labels),
      timestamp: DateTime.now(),
      inferenceTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Loads label strings from the assets text file.
  Future<List<String>> _loadLabels() async {
    final rawLabels = await rootBundle.loadString(labelsPath);
    return rawLabels
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }

  /// Applies softmax normalization to raw logits.
  /// Converts raw model output into probability distribution summing to 1.0.
  ///
  /// Uses numerically stable computation (subtract max before exp).
  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }

  /// Releases the interpreter and frees native resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
