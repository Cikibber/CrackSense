
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drone_crack_detection/services/mqtt/mqtt_providers.dart';
import 'package:drone_crack_detection/features/live_feed/domain/models/detection_result.dart';

/// Provider for the currently displayed camera frame (from MQTT or simulation).
final displayedFrameProvider = Provider((ref) {
  return ref.watch(cachedFrameProvider);
});

/// Provider that tracks whether the live feed has received any frame.
final hasReceivedFrameProvider = Provider<bool>((ref) {
  return ref.watch(cachedFrameProvider) != null;
});

/// Provider tracking current analysis state for the live feed screen.
final liveFeedAnalysisProvider =
    NotifierProvider.autoDispose<LiveFeedAnalysisNotifier, LiveFeedAnalysisState>(
        LiveFeedAnalysisNotifier.new);

class LiveFeedAnalysisState {
  final bool isAnalyzing;
  final DetectionResult? lastResult;
  final String? errorMessage;

  const LiveFeedAnalysisState({
    this.isAnalyzing = false,
    this.lastResult,
    this.errorMessage,
  });

  LiveFeedAnalysisState copyWith({
    bool? isAnalyzing,
    DetectionResult? lastResult,
    String? errorMessage,
  }) {
    return LiveFeedAnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LiveFeedAnalysisNotifier extends Notifier<LiveFeedAnalysisState> {
  @override
  LiveFeedAnalysisState build() {
    return const LiveFeedAnalysisState();
  }

  void startAnalysis() {
    state = state.copyWith(isAnalyzing: true, errorMessage: null);
  }

  void completeAnalysis(DetectionResult result) {
    state = LiveFeedAnalysisState(
      isAnalyzing: false,
      lastResult: result,
    );
  }

  void setError(String message) {
    state = LiveFeedAnalysisState(
      isAnalyzing: false,
      errorMessage: message,
    );
  }

  void clearResult() {
    state = const LiveFeedAnalysisState();
  }
}
