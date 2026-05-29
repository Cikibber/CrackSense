import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/domain/models/drone_telemetry.dart';
import 'mqtt_service.dart';

/// Singleton provider for the MQTT service instance.
final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider for MQTT connection state changes.
final connectionStateProvider =
    StreamProvider<AppConnectionState>((ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.connectionStateStream;
});

/// Stream provider for real-time drone telemetry updates.
final telemetryStreamProvider = StreamProvider<DroneTelemetry>((ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.telemetryStream;
});

/// Stream provider for incoming camera frames (base64-decoded JPEG bytes).
final cameraFrameStreamProvider = StreamProvider<Uint8List>((ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.cameraFrameStream;
});

/// Provider for the last-known telemetry (cached for offline display).
final cachedTelemetryProvider =
    NotifierProvider<CachedTelemetryNotifier, DroneTelemetry>(
        CachedTelemetryNotifier.new);

/// Notifier that caches the latest telemetry for offline access.
class CachedTelemetryNotifier extends Notifier<DroneTelemetry> {
  @override
  DroneTelemetry build() {
    ref.listen<AsyncValue<DroneTelemetry>>(telemetryStreamProvider, (_, next) {
      next.whenData((data) => state = data);
    });
    return DroneTelemetry.initial();
  }

  void update(DroneTelemetry telemetry) {
    state = telemetry;
  }
}

/// Provider for the last received camera frame (cached).
final cachedFrameProvider =
    NotifierProvider<CachedFrameNotifier, Uint8List?>(CachedFrameNotifier.new);

/// Notifier that caches the latest camera frame.
class CachedFrameNotifier extends Notifier<Uint8List?> {
  @override
  Uint8List? build() {
    ref.listen<AsyncValue<Uint8List>>(cameraFrameStreamProvider, (_, next) {
      next.whenData((data) => state = data);
    });
    return null;
  }

  void update(Uint8List frame) {
    state = frame;
  }
}
