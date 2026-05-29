import '../models/detection_record.dart';

/// Abstract interface for detection history persistence.
abstract class HistoryRepository {
  /// Returns all saved detection records, newest first.
  Future<List<DetectionRecord>> getAllRecords();

  /// Returns a single record by its unique ID.
  Future<DetectionRecord?> getRecordById(String id);

  /// Saves a new detection record.
  Future<void> saveRecord(DetectionRecord record);

  /// Deletes a record by its unique ID.
  Future<void> deleteRecord(String id);

  /// Deletes all records.
  Future<void> clearAll();

  /// Returns the total count of saved records.
  Future<int> getRecordCount();

  /// Returns records filtered by classification type.
  Future<List<DetectionRecord>> getRecordsByClassification(String classification);
}
