import 'package:flutter/foundation.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:secure_application/secure_application.dart';

/// Runtime control surface for [AppShield] / [SecureScope].
///
/// Attach an instance to [AppShield.controller] (or manage screenshot prevention
/// independently) to lock the app, unlock it, or toggle screenshot blocking
/// without rebuilding the widget tree.
class AppShieldController extends ChangeNotifier {
  SecureApplicationController? _secureController;
  final NoScreenshot _noScreenshot;
  bool _screenshotPreventionEnabled = false;
  bool _attached = false;
  bool _locked = false;

  /// Optional hook invoked when [unlock] is called and biometric auth is needed.
  ///
  /// Should return `true` when authentication succeeds.
  Future<bool> Function()? authenticate;

  /// Creates an [AppShieldController].
  ///
  /// Pass [noScreenshot] only for tests.
  AppShieldController({NoScreenshot? noScreenshot})
    : _noScreenshot = noScreenshot ?? NoScreenshot.instance;

  /// Whether this controller is attached to a live [AppShield] state.
  bool get isAttached => _attached;

  /// Whether the secure gate currently considers the app locked.
  bool get isLocked => _locked;

  /// Whether screenshot / recording prevention is currently enabled.
  bool get isScreenshotPreventionEnabled => _screenshotPreventionEnabled;

  /// Called by [AppShield] when the secure application controller is ready.
  @internal
  void attach({
    required SecureApplicationController? secureController,
    required bool screenshotPreventionEnabled,
  }) {
    _secureController = secureController;
    _screenshotPreventionEnabled = screenshotPreventionEnabled;
    _attached = true;
    _locked = secureController?.locked ?? false;
    notifyListeners();
  }

  /// Called by [AppShield] on dispose.
  @internal
  void detach() {
    _secureController = null;
    _attached = false;
    notifyListeners();
  }

  /// Syncs locked state from the underlying secure controller.
  @internal
  void syncLocked(bool locked) {
    if (_locked == locked) return;
    _locked = locked;
    notifyListeners();
  }

  /// Locks the app (shows the secure gate / blur overlay).
  Future<void> lock() async {
    _secureController?.lock();
    _locked = true;
    notifyListeners();
  }

  /// Attempts to unlock the app.
  ///
  /// If [authenticate] is set, it runs first; unlock only proceeds on success.
  /// Returns whether the app ended up unlocked.
  Future<bool> unlock() async {
    if (authenticate != null) {
      final bool ok = await authenticate!();
      if (!ok) return false;
    }
    _secureController?.authSuccess(unlock: true);
    _secureController?.unlock();
    _locked = false;
    notifyListeners();
    return true;
  }

  /// Enables or disables screenshot / screen-recording prevention at runtime.
  Future<bool> setScreenshotPrevention(bool enabled) async {
    try {
      final bool result = enabled
          ? await _noScreenshot.screenshotOff()
          : await _noScreenshot.screenshotOn();
      if (result) {
        _screenshotPreventionEnabled = enabled;
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('setScreenshotPrevention failed: $e');
      return false;
    }
  }
}
