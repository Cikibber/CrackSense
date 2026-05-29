import 'dart:typed_data';
import 'package:hive_ce/hive.dart';

part 'detection_record.g.dart';

/// A persisted record of a crack detection event, stored locally via Hive.
@HiveType(typeId: 0)
class DetectionRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String classification;

  @HiveField(2)
  final double confidence;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final Uint8List? imageBytes;

  @HiveField(5)
  final double? latitude;

  @HiveField(6)
  final double? longitude;

  @HiveField(7)
  final double? altitude;

  @HiveField(8)
  final int inferenceTimeMs;

  DetectionRecord({
    required this.id,
    required this.classification,
    required this.confidence,
    required this.timestamp,
    this.imageBytes,
    this.latitude,
    this.longitude,
    this.altitude,
    this.inferenceTimeMs = 0,
  });

  /// Whether this detection found a crack.
  bool get hasCrack => true;

  /// Severity level as a 0–3 scale.
  int get severityLevel {
    switch (classification.toLowerCase()) {
      case 'vertical':
        return 1;
      case 'horizontal':
        return 2;
      case 'diagonal':
        return 3;
      default:
        return 1;
    }
  }

  /// Confidence as a formatted percentage string.
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  @override
  String toString() {
    return 'DetectionRecord($id: $classification @ $confidencePercent)';
  }
}
