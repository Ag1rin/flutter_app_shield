import 'package:flutter/foundation.dart';
import 'package:no_screenshot/no_screenshot.dart';

/// Reference-counted screenshot prevention shared by [AppShield] and [SecureScope].
///
/// Nested scopes safely share a single native prevention claim: prevention stays
/// on until the last holder releases it.
class ScreenshotPrevention {
  ScreenshotPrevention._();

  static final ScreenshotPrevention instance = ScreenshotPrevention._();

  final NoScreenshot _plugin = NoScreenshot.instance;
  int _holders = 0;

  /// Number of active scopes currently requesting prevention.
  int get holders => _holders;

  /// Whether prevention is currently claimed by at least one holder.
  bool get isEnabled => _holders > 0;

  /// Acquires a prevention claim. The first holder turns native prevention on.
  Future<bool> acquire() async {
    _holders++;
    if (_holders == 1) {
      try {
        return await _plugin.screenshotOff();
      } catch (e) {
        debugPrint('ScreenshotPrevention.acquire failed: $e');
        return false;
      }
    }
    return true;
  }

  /// Releases a prevention claim. The last holder turns native prevention off.
  Future<bool> release() async {
    if (_holders <= 0) {
      _holders = 0;
      return true;
    }
    _holders--;
    if (_holders == 0) {
      try {
        return await _plugin.screenshotOn();
      } catch (e) {
        debugPrint('ScreenshotPrevention.release failed: $e');
        return false;
      }
    }
    return true;
  }

  /// Forces prevention off and clears all holders (useful in tests).
  @visibleForTesting
  Future<void> reset() async {
    _holders = 0;
    try {
      await _plugin.screenshotOn();
    } catch (_) {}
  }
}
