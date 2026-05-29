import '../../domain/models/detection_record.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/hive_detection_datasource.dart';

/// Concrete implementation of [HistoryRepository] using Hive local storage.
class HistoryRepositoryImpl implements HistoryRepository {
  final HiveDetectionDatasource _datasource;

  HistoryRepositoryImpl(this._datasource);

  @override
  Future<List<DetectionRecord>> getAllRecords() async {
    return _datasource.getAllRecords();
  }

  @override
  Future<DetectionRecord?> getRecordById(String id) async {
    return _datasource.getRecordById(id);
  }

  @override
  Future<void> saveRecord(DetectionRecord record) async {
    await _datasource.saveRecord(record);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _datasource.deleteRecord(id);
  }

  @override
  Future<void> clearAll() async {
    await _datasource.clearAll();
  }

  @override
  Future<int> getRecordCount() async {
    return _datasource.getRecordCount();
  }

  @override
  Future<List<DetectionRecord>> getRecordsByClassification(
      String classification) async {
    return _datasource.getRecordsByClassification(classification);
  }
}
