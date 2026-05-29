import 'package:hive_ce/hive.dart';

import '../../domain/models/detection_record.dart';
import '../../../../services/storage/hive_service.dart';

/// Hive-backed data source for detection record CRUD operations.
class HiveDetectionDatasource {
  final HiveService _hiveService;

  HiveDetectionDatasource(this._hiveService);

  Box<DetectionRecord> get _box => _hiveService.detectionBox;

  /// Returns all records sorted by timestamp descending (newest first).
  List<DetectionRecord> getAllRecords() {
    final records = _box.values.toList();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  /// Finds a record by its unique string ID.
  DetectionRecord? getRecordById(String id) {
    try {
      return _box.values.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Persists a new detection record, keyed by its ID.
  Future<void> saveRecord(DetectionRecord record) async {
    await _box.put(record.id, record);
  }

  /// Removes a record by its unique string ID.
  Future<void> deleteRecord(String id) async {
    final record = getRecordById(id);
    if (record != null) {
      await record.delete();
    }
  }

  /// Removes all records from the box.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Returns the total number of stored records.
  int getRecordCount() => _box.length;

  /// Returns records matching a specific classification label.
  List<DetectionRecord> getRecordsByClassification(String classification) {
    return _box.values
        .where(
            (r) => r.classification.toLowerCase() == classification.toLowerCase())
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
