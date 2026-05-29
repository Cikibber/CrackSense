/// MQTT topic and connection constants for drone communication.
class MqttConstants {
  MqttConstants._();

  // ── Broker Configuration ─────────────────────────────────────────
  static const String brokerHost = 'broker.hivemq.com';
  static const int brokerPort = 1883;
  static const String clientIdPrefix = 'drone_crack_app_';

  // ── Keep Alive & Timeouts ────────────────────────────────────────
  static const int keepAlivePeriod = 30;
  static const int connectionTimeoutMs = 5000;
  static const int reconnectDelayBaseMs = 1000;
  static const int reconnectDelayMaxMs = 30000;
  static const int maxReconnectAttempts = 10;

  // ── Telemetry Topics (Subscribe) ─────────────────────────────────
  static const String topicTelemetryBattery = 'drone/telemetry/battery';
  static const String topicTelemetryAltitude = 'drone/telemetry/altitude';
  static const String topicTelemetrySignal = 'drone/telemetry/signal';
  static const String topicTelemetryStatus = 'drone/telemetry/status';
  static const String topicCameraFrame = 'drone/camera/frame';

  // ── Command Topics (Publish) ─────────────────────────────────────
  static const String topicCommandCapture = 'drone/command/capture';
  static const String topicCommandMode = 'drone/command/mode';

  // ── Quality of Service ───────────────────────────────────────────
  static const int telemetryQos = 1;
  static const int commandQos = 1;
  static const int cameraQos = 0; // Best-effort for video frames

  // ── Simulation Mode ──────────────────────────────────────────────
  static const bool enableSimulation = true;
  static const int simulationIntervalMs = 2000;
}
