import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hive_service.dart';

/// Singleton provider for the Hive storage service.
final hiveServiceProvider = Provider<HiveService>((ref) {
  final service = HiveService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Future provider that initializes Hive. 
/// Should be awaited before the app renders.
final hiveInitProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(hiveServiceProvider);
  await service.initialize();
  return true;
});
