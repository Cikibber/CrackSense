/// Represents real-time telemetry data received from the drone via MQTT.
class DroneTelemetry {
  final int batteryPercent;
  final double altitudeMeters;
  final int signalStrength;
  final DroneStatus status;
  final DateTime timestamp;

  const DroneTelemetry({
    required this.batteryPercent,
    required this.altitudeMeters,
    required this.signalStrength,
    required this.status,
    required this.timestamp,
  });

  /// Creates a default telemetry with zeroed values (used before first data).
  factory DroneTelemetry.initial() {
    return DroneTelemetry(
      batteryPercent: 0,
      altitudeMeters: 0.0,
      signalStrength: 0,
      status: DroneStatus.disconnected,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a copy with optional overrides.
  DroneTelemetry copyWith({
    int? batteryPercent,
    double? altitudeMeters,
    int? signalStrength,
    DroneStatus? status,
    DateTime? timestamp,
  }) {
    return DroneTelemetry(
      batteryPercent: batteryPercent ?? this.batteryPercent,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      signalStrength: signalStrength ?? this.signalStrength,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Battery level descriptor for accessibility.
  String get batteryLabel {
    if (batteryPercent > 75) return 'Full';
    if (batteryPercent > 50) return 'Good';
    if (batteryPercent > 25) return 'Low';
    return 'Critical';
  }

  /// Signal quality descriptor for accessibility.
  String get signalLabel {
    if (signalStrength > 75) return 'Excellent';
    if (signalStrength > 50) return 'Good';
    if (signalStrength > 25) return 'Weak';
    return 'Poor';
  }

  @override
  String toString() {
    return 'DroneTelemetry(battery: $batteryPercent%, altitude: ${altitudeMeters}m, '
        'signal: $signalStrength%, status: ${status.name})';
  }
}

/// Possible drone operational states.
enum DroneStatus {
  disconnected,
  connecting,
  idle,
  scanning,
  returning,
  error;

  String get displayName {
    switch (this) {
      case DroneStatus.disconnected:
        return 'Disconnected';
      case DroneStatus.connecting:
        return 'Connecting';
      case DroneStatus.idle:
        return 'Idle';
      case DroneStatus.scanning:
        return 'Scanning';
      case DroneStatus.returning:
        return 'Returning';
      case DroneStatus.error:
        return 'Error';
    }
  }

  /// Parses a status string from MQTT payload.
  static DroneStatus fromString(String value) {
    return DroneStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DroneStatus.disconnected,
    );
  }
}
