import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drone_crack_detection/services/storage/storage_providers.dart';
import 'package:drone_crack_detection/features/history/data/datasources/hive_detection_datasource.dart';
import 'package:drone_crack_detection/features/history/data/repositories/history_repository_impl.dart';
import 'package:drone_crack_detection/features/history/domain/models/detection_record.dart';
import 'package:drone_crack_detection/features/history/domain/repositories/history_repository.dart';

/// Provider for the Hive detection data source.
final hiveDetectionDatasourceProvider =
    Provider<HiveDetectionDatasource>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return HiveDetectionDatasource(hiveService);
});

/// Provider for the history repository implementation.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final datasource = ref.watch(hiveDetectionDatasourceProvider);
  return HistoryRepositoryImpl(datasource);
});

/// Provider that loads all detection records from storage.
/// Invalidate this provider to refresh the list.
final allDetectionRecordsProvider =
    FutureProvider<List<DetectionRecord>>((ref) async {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.getAllRecords();
});

/// State provider for the currently selected filter classification.
/// null = show all, "Hairline" = show only hairline, etc.
final selectedFilterProvider = NotifierProvider<SelectedFilterNotifier, String?>(SelectedFilterNotifier.new);

class SelectedFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

/// Filtered records based on the selected classification filter.
final filteredRecordsProvider =
    FutureProvider<List<DetectionRecord>>((ref) async {
  final filter = ref.watch(selectedFilterProvider);
  final repository = ref.watch(historyRepositoryProvider);

  if (filter == null || filter.isEmpty) {
    return repository.getAllRecords();
  }
  return repository.getRecordsByClassification(filter);
});

/// Provider for the total record count.
final recordCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.getRecordCount();
});
