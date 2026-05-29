import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../core/constants/mqtt_constants.dart';
import '../../features/dashboard/domain/models/drone_telemetry.dart';

/// Connection state for the app's MQTT client.
enum AppConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Service responsible for all MQTT communication with the drone.
///
/// Handles:
/// - Connecting to the HiveMQ broker with auto-reconnect
/// - Subscribing to telemetry + camera topics
/// - Publishing command messages
/// - Exposing reactive streams for telemetry and camera frames
/// - Optional simulation mode for development without a real drone
class MqttService {
  MqttServerClient? _client;
  Timer? _reconnectTimer;
  Timer? _simulationTimer;
  int _reconnectAttempts = 0;

  // ── Stream Controllers ───────────────────────────────────────────
  final _connectionStateController =
      StreamController<AppConnectionState>.broadcast();
  final _telemetryController = StreamController<DroneTelemetry>.broadcast();
  final _cameraFrameController = StreamController<Uint8List>.broadcast();

  // ── Public Streams ───────────────────────────────────────────────
  Stream<AppConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<DroneTelemetry> get telemetryStream => _telemetryController.stream;
  Stream<Uint8List> get cameraFrameStream => _cameraFrameController.stream;

  // ── Current State ────────────────────────────────────────────────
  AppConnectionState _currentState = AppConnectionState.disconnected;
  AppConnectionState get currentState => _currentState;

  DroneTelemetry _lastTelemetry = DroneTelemetry.initial();
  DroneTelemetry get lastTelemetry => _lastTelemetry;

  Uint8List? _lastFrame;
  Uint8List? get lastFrame => _lastFrame;

  /// Connects to the MQTT broker. If [simulate] is true, generates
  /// fake telemetry data without actually connecting to a broker.
  Future<void> connect({bool simulate = MqttConstants.enableSimulation}) async {
    if (simulate) {
      _startSimulation();
      return;
    }

    _updateConnectionState(AppConnectionState.connecting);

    final clientId =
        '${MqttConstants.clientIdPrefix}${DateTime.now().millisecondsSinceEpoch}';

    _client = MqttServerClient.withPort(
      MqttConstants.brokerHost,
      clientId,
      MqttConstants.brokerPort,
    );

    _client!.logging(on: false);
    _client!.keepAlivePeriod = MqttConstants.keepAlivePeriod;
    _client!.autoReconnect = true;
    _client!.onAutoReconnect = _onAutoReconnect;
    _client!.onAutoReconnected = _onAutoReconnected;
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;

    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    try {
      await _client!.connect();
    } catch (e) {
      _updateConnectionState(AppConnectionState.error);
      _client?.disconnect();
      _scheduleReconnect();
    }
  }

  /// Disconnects from the broker and cleans up resources.
  void disconnect() {
    _reconnectTimer?.cancel();
    _simulationTimer?.cancel();
    _client?.disconnect();
    _updateConnectionState(AppConnectionState.disconnected);
  }

  /// Publishes a capture command to the drone.
  void triggerCapture() {
    _publish(
      MqttConstants.topicCommandCapture,
      json.encode({
        'command': 'capture',
        'timestamp': DateTime.now().toIso8601String(),
      }),
      qos: MqttConstants.commandQos,
    );
  }

  /// Publishes a mode-change command to the drone.
  void setDroneMode(String mode) {
    _publish(
      MqttConstants.topicCommandMode,
      json.encode({
        'mode': mode,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      qos: MqttConstants.commandQos,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Private: Connection Callbacks
  // ═══════════════════════════════════════════════════════════════════

  void _onConnected() {
    _reconnectAttempts = 0;
    _updateConnectionState(AppConnectionState.connected);
    _subscribeToTopics();
  }

  void _onDisconnected() {
    _updateConnectionState(AppConnectionState.disconnected);
  }

  void _onAutoReconnect() {
    _updateConnectionState(AppConnectionState.connecting);
  }

  void _onAutoReconnected() {
    _updateConnectionState(AppConnectionState.connected);
    _subscribeToTopics();
  }

  // ═══════════════════════════════════════════════════════════════════
  // Private: Topic Management
  // ═══════════════════════════════════════════════════════════════════

  void _subscribeToTopics() {
    if (_client == null ||
        _client!.connectionStatus?.state != MqttConnectionState.connected) {
      return;
    }

    final telemetryQos = MqttQos.values[MqttConstants.telemetryQos];
    final cameraQos = MqttQos.values[MqttConstants.cameraQos];

    _client!.subscribe(MqttConstants.topicTelemetryBattery, telemetryQos);
    _client!.subscribe(MqttConstants.topicTelemetryAltitude, telemetryQos);
    _client!.subscribe(MqttConstants.topicTelemetrySignal, telemetryQos);
    _client!.subscribe(MqttConstants.topicTelemetryStatus, telemetryQos);
    _client!.subscribe(MqttConstants.topicCameraFrame, cameraQos);

    _client!.updates?.listen(_onMessage);
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final payload = message.payload as MqttPublishMessage;
      final payloadString = MqttPublishPayload.bytesToStringAsString(
        payload.payload.message,
      );

      switch (topic) {
        case MqttConstants.topicTelemetryBattery:
          final battery = int.tryParse(payloadString) ?? _lastTelemetry.batteryPercent;
          _lastTelemetry = _lastTelemetry.copyWith(
            batteryPercent: battery.clamp(0, 100),
            timestamp: DateTime.now(),
          );
          _telemetryController.add(_lastTelemetry);
          break;

        case MqttConstants.topicTelemetryAltitude:
          final altitude =
              double.tryParse(payloadString) ?? _lastTelemetry.altitudeMeters;
          _lastTelemetry = _lastTelemetry.copyWith(
            altitudeMeters: altitude,
            timestamp: DateTime.now(),
          );
          _telemetryController.add(_lastTelemetry);
          break;

        case MqttConstants.topicTelemetrySignal:
          final signal =
              int.tryParse(payloadString) ?? _lastTelemetry.signalStrength;
          _lastTelemetry = _lastTelemetry.copyWith(
            signalStrength: signal.clamp(0, 100),
            timestamp: DateTime.now(),
          );
          _telemetryController.add(_lastTelemetry);
          break;

        case MqttConstants.topicTelemetryStatus:
          _lastTelemetry = _lastTelemetry.copyWith(
            status: DroneStatus.fromString(payloadString),
            timestamp: DateTime.now(),
          );
          _telemetryController.add(_lastTelemetry);
          break;

        case MqttConstants.topicCameraFrame:
          try {
            final frameBytes = base64Decode(payloadString);
            _lastFrame = frameBytes;
            _cameraFrameController.add(frameBytes);
          } catch (_) {
            // Ignore malformed camera frames
          }
          break;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Private: Publishing
  // ═══════════════════════════════════════════════════════════════════

  void _publish(String topic, String payload, {int qos = 1}) {
    if (_client == null ||
        _client!.connectionStatus?.state != MqttConnectionState.connected) {
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _client!.publishMessage(
      topic,
      MqttQos.values[qos],
      builder.payload!,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Private: Reconnect Logic
  // ═══════════════════════════════════════════════════════════════════

  void _scheduleReconnect() {
    if (_reconnectAttempts >= MqttConstants.maxReconnectAttempts) {
      _updateConnectionState(AppConnectionState.error);
      return;
    }

    _reconnectAttempts++;
    final delayMs = min(
      MqttConstants.reconnectDelayBaseMs * pow(2, _reconnectAttempts - 1),
      MqttConstants.reconnectDelayMaxMs,
    ).toInt();

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      connect(simulate: false);
    });
  }

  void _updateConnectionState(AppConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  // ═══════════════════════════════════════════════════════════════════
  // Simulation Mode (for development without a real drone)
  // ═══════════════════════════════════════════════════════════════════

  final Random _random = Random();

  void _startSimulation() {
    _updateConnectionState(AppConnectionState.connecting);

    // Simulate a short connection delay
    Future.delayed(const Duration(milliseconds: 800), () {
      _updateConnectionState(AppConnectionState.connected);

      // Initialize with realistic starting values
      _lastTelemetry = DroneTelemetry(
        batteryPercent: 94,
        altitudeMeters: 12.5,
        signalStrength: 88,
        status: DroneStatus.scanning,
        timestamp: DateTime.now(),
      );
      _telemetryController.add(_lastTelemetry);

      // Periodically update with slightly varying values
      _simulationTimer = Timer.periodic(
        Duration(milliseconds: MqttConstants.simulationIntervalMs),
        (_) => _emitSimulatedTelemetry(),
      );
    });
  }

  void _emitSimulatedTelemetry() {
    final batteryDrain = _random.nextInt(2); // 0-1% drain per tick
    final altitudeJitter = (_random.nextDouble() - 0.5) * 1.5; // ±0.75m
    final signalJitter = (_random.nextInt(7)) - 3; // ±3%

    _lastTelemetry = _lastTelemetry.copyWith(
      batteryPercent:
          (_lastTelemetry.batteryPercent - batteryDrain).clamp(5, 100),
      altitudeMeters:
          (_lastTelemetry.altitudeMeters + altitudeJitter).clamp(0.0, 120.0),
      signalStrength:
          (_lastTelemetry.signalStrength + signalJitter).clamp(20, 100),
      status: DroneStatus.scanning,
      timestamp: DateTime.now(),
    );

    _telemetryController.add(_lastTelemetry);
  }

  // ═══════════════════════════════════════════════════════════════════
  // Cleanup
  // ═══════════════════════════════════════════════════════════════════

  void dispose() {
    disconnect();
    _connectionStateController.close();
    _telemetryController.close();
    _cameraFrameController.close();
  }
}
