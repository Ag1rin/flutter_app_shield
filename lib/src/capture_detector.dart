import 'package:flutter/foundation.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

/// Snapshot of a capture-related event from the platform.
class CaptureEvent {
  /// When the event was observed.
  final DateTime timestamp;

  /// Optional platform path or metadata string when available.
  final String? detail;

  /// Source app reported by the platform, if any.
  final String? sourceApp;

  /// Creates a [CaptureEvent].
  const CaptureEvent({
    required this.timestamp,
    this.detail,
    this.sourceApp,
  });

  /// Builds a [CaptureEvent] from a [ScreenshotSnapshot].
  factory CaptureEvent.fromSnapshot(ScreenshotSnapshot snapshot) {
    final int ms = snapshot.timestamp;
    return CaptureEvent(
      timestamp: ms > 0
          ? DateTime.fromMillisecondsSinceEpoch(ms)
          : DateTime.now(),
      detail: snapshot.screenshotPath.isEmpty ? null : snapshot.screenshotPath,
      sourceApp: snapshot.sourceApp.isEmpty ? null : snapshot.sourceApp,
    );
  }
}

/// Listens for screenshot and screen-recording events via [NoScreenshot].
class CaptureDetector {
  final NoScreenshot _plugin;
  bool _listening = false;

  /// Called when a screenshot is detected.
  void Function(CaptureEvent event)? onScreenshot;

  /// Called when screen recording starts.
  void Function(CaptureEvent event)? onScreenRecordingStarted;

  /// Called when screen recording stops.
  void Function(CaptureEvent event)? onScreenRecordingStopped;

  /// Creates a [CaptureDetector].
  ///
  /// Pass [plugin] only for tests; production code uses [NoScreenshot.instance].
  CaptureDetector({NoScreenshot? plugin})
    : _plugin = plugin ?? NoScreenshot.instance;

  /// Whether listening is currently active.
  bool get isListening => _listening;

  /// Starts screenshot and screen-recording listeners.
  Future<void> start() async {
    if (_listening) return;
    _listening = true;

    _plugin.onScreenshotDetected = (snapshot) {
      onScreenshot?.call(CaptureEvent.fromSnapshot(snapshot));
    };
    _plugin.onScreenRecordingStarted = (snapshot) {
      onScreenRecordingStarted?.call(CaptureEvent.fromSnapshot(snapshot));
    };
    _plugin.onScreenRecordingStopped = (snapshot) {
      onScreenRecordingStopped?.call(CaptureEvent.fromSnapshot(snapshot));
    };

    try {
      _plugin.startCallbacks();
      await _plugin.startScreenshotListening();
      await _plugin.startScreenRecordingListening();
    } catch (e) {
      debugPrint('CaptureDetector.start failed: $e');
    }
  }

  /// Stops listeners and clears callback hooks.
  Future<void> stop() async {
    if (!_listening) return;
    _listening = false;

    try {
      await _plugin.stopScreenshotListening();
      await _plugin.stopScreenRecordingListening();
      _plugin.stopCallbacks();
      _plugin.removeAllCallbacks();
    } catch (e) {
      debugPrint('CaptureDetector.stop failed: $e');
    }
  }

  /// Releases resources.
  Future<void> dispose() => stop();
}
