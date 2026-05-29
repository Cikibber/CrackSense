import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drone_crack_detection/services/mqtt/mqtt_providers.dart';
import 'package:drone_crack_detection/services/mqtt/mqtt_service.dart';

/// Convenience provider that maps MQTT connection state to a display-friendly format.
final connectionDisplayProvider = Provider<ConnectionDisplay>((ref) {
  final connectionAsync = ref.watch(connectionStateProvider);

  return connectionAsync.when(
    data: (state) {
      switch (state) {
        case AppConnectionState.connected:
          return const ConnectionDisplay(
            label: 'Connected',
            isConnected: true,
            isConnecting: false,
          );
        case AppConnectionState.connecting:
          return const ConnectionDisplay(
            label: 'Connecting...',
            isConnected: false,
            isConnecting: true,
          );
        case AppConnectionState.disconnected:
          return const ConnectionDisplay(
            label: 'Disconnected',
            isConnected: false,
            isConnecting: false,
          );
        case AppConnectionState.error:
          return const ConnectionDisplay(
            label: 'Connection Error',
            isConnected: false,
            isConnecting: false,
            hasError: true,
          );
      }
    },
    loading: () => const ConnectionDisplay(
      label: 'Initializing...',
      isConnected: false,
      isConnecting: true,
    ),
    error: (_, __) => const ConnectionDisplay(
      label: 'Error',
      isConnected: false,
      isConnecting: false,
      hasError: true,
    ),
  );
});

/// Data class for connection display state.
class ConnectionDisplay {
  final String label;
  final bool isConnected;
  final bool isConnecting;
  final bool hasError;

  const ConnectionDisplay({
    required this.label,
    required this.isConnected,
    required this.isConnecting,
    this.hasError = false,
  });
}
