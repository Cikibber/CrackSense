/// Result of a single crack detection inference from the TFLite model.
class DetectionResult {
  final String classification;
  final double confidence;
  final List<double> allConfidences;
  final List<String> allLabels;
  final DateTime timestamp;
  final int inferenceTimeMs;

  const DetectionResult({
    required this.classification,
    required this.confidence,
    required this.allConfidences,
    required this.allLabels,
    required this.timestamp,
    required this.inferenceTimeMs,
  });

  /// Whether the detection found a crack (anything other than "Safe").
  bool get hasCrack => true;

  /// Returns the severity level as a normalized 0–3 scale.
  int get severityLevel {
    switch (classification.toLowerCase()) {
      case 'vertical':
      case 'vertikal':
        return 1;
      case 'horizontal':
        return 2;
      case 'diagonal':
        return 3;
      default:
        return 1;
    }
  }

  /// Returns the cause of the crack based on its classification.
  String get cause {
    switch (classification.toLowerCase()) {
      case 'vertical':
      case 'vertikal':
        return 'Muai-susut termal, penyusutan mortar, pergerakan struktur utama';
      case 'horizontal':
        return 'Kualitas mortar buruk, penyusutan plester, pergerakan antar lantai (interstory drift)';
      case 'diagonal':
        return 'Konsentrasi tegangan pada sudut bukaan pintu/jendela, pergerakan struktur utama, penyusutan tidak merata';
      default:
        return 'Penyebab tidak diketahui';
    }
  }

  /// Returns the suggested treatment for the crack based on its classification.
  String get treatment {
    switch (classification.toLowerCase()) {
      case 'vertical':
      case 'vertikal':
      case 'horizontal':
      case 'diagonal':
        return 'V-cut';
      default:
        return 'Konsultasikan dengan ahli struktural';
    }
  }

  /// Confidence as a percentage string.
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Creates a simulated result for testing/demo purposes.
  factory DetectionResult.simulated({
    String classification = 'Vertical',
    double confidence = 0.87,
  }) {
    return DetectionResult(
      classification: classification,
      confidence: confidence,
      allConfidences: [0.87, 0.08, 0.05],
      allLabels: ['Vertical', 'Horizontal', 'Diagonal'],
      timestamp: DateTime.now(),
      inferenceTimeMs: 45,
    );
  }

  @override
  String toString() {
    return 'DetectionResult($classification: $confidencePercent, ${inferenceTimeMs}ms)';
  }
}
