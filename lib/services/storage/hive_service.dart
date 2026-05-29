import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../features/history/domain/models/detection_record.dart';

/// Service for initializing and managing Hive local storage.
///
/// Handles:
/// - Hive database initialization
/// - Type adapter registration
/// - Box lifecycle management
class HiveService {
  static const String detectionBoxName = 'detection_records';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes Hive storage and registers all type adapters.
  /// Must be called once at app startup before accessing any boxes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register type adapters
    if (!Hive.isAdapterRegistered(DetectionRecordAdapter().typeId)) {
      Hive.registerAdapter(DetectionRecordAdapter());
    }

    // Open all required boxes
    await Hive.openBox<DetectionRecord>(detectionBoxName);

    _isInitialized = true;
  }

  /// Returns the detection records box.
  /// Throws if [initialize] has not been called.
  Box<DetectionRecord> get detectionBox {
    if (!_isInitialized) {
      throw StateError('HiveService not initialized. Call initialize() first.');
    }
    return Hive.box<DetectionRecord>(detectionBoxName);
  }

  /// Closes all open boxes and releases resources.
  Future<void> dispose() async {
    await Hive.close();
    _isInitialized = false;
  }
}
