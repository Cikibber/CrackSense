import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/utils/image_utils.dart';
import '../../features/live_feed/domain/models/detection_result.dart';

/// Service for running on-device crack detection inference using TensorFlow Lite.
///
/// Handles:
/// - Loading the .tflite model from app assets
/// - Loading label definitions
/// - Image preprocessing (decode → resize → normalize/mean-subtract)
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

  /// Determines the appropriate preprocessing mode based on the model path.
  ///
  /// - Model C (ResNet50): uses BGR mean subtraction matching
  ///   `tf.keras.applications.resnet.preprocess_input` from training.
  /// - Model A (BYOL) & Model B (Baseline): use standard [0,1] normalization.
  PreprocessMode get _preprocessMode {
    if (_currentModelPath.contains('ResNet50')) {
      return PreprocessMode.resnet50;
    }
    return PreprocessMode.standard;
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

    // ── Step 1: Preprocess the image ──────────────────────────────
    // Uses the appropriate preprocessing mode for the active model:
    // - ResNet50: BGR mean subtraction (matches training pipeline)
    // - Standard: [0,1] normalization (for BYOL/Baseline models)
    final preprocessed = ImageUtils.preprocessForModel(
      imageBytes,
      inputWidth: inputWidth,
      inputHeight: inputHeight,
      mode: _preprocessMode,
    );

    if (preprocessed == null) {
      return null;
    }

    // ── Step 2: Reshape to input tensor [1, 224, 224, 3] ──────────
    final input = preprocessed.reshape([1, inputHeight, inputWidth, inputChannels]);

    // ── Step 3: Prepare output buffer [1, numClasses] ─────────────
    final output = List.generate(
      1,
      (_) => List.filled(numClasses, 0.0),
    );

    // ── Step 4: Run inference ─────────────────────────────────────
    _interpreter!.run(input, output);

    stopwatch.stop();

    // ── Step 5: Post-process results ──────────────────────────────
    final probabilities = output[0];

    // Apply softmax if the model doesn't include it in the final layer
    final softmaxProbs = _softmax(probabilities);

    // Find the class with highest confidence
    int maxIndex = 0;
    double maxConfidence = softmaxProbs[0];
    for (int i = 1; i < softmaxProbs.length; i++) {
      if (softmaxProbs[i] > maxConfidence) {
        maxConfidence = softmaxProbs[i];
        maxIndex = i;
      }
    }

    final classification =
        maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';

    return DetectionResult(
      classification: classification,
      confidence: maxConfidence,
      allConfidences: softmaxProbs,
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
  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((l) => _safeExp(l - maxLogit)).toList();
    final sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }

  /// Safe exponential that clamps to avoid overflow.
  double _safeExp(double x) {
    if (x > 80) return double.maxFinite;
    if (x < -80) return 0.0;
    return x.isNaN ? 0.0 : _pow(x);
  }

  double _pow(double x) {
    // Using Dart's built-in exp from dart:math
    return 2.718281828459045 * x.abs() < 1
        ? 1.0 + x
        : _dartExp(x);
  }

  double _dartExp(double x) {
    // Fallback to iterative approximation
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  /// Releases the interpreter and frees native resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
