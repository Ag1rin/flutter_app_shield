import 'package:flutter/foundation.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:secure_application/secure_application.dart';

import 'screenshot_prevention.dart';

/// Runtime control surface for [AppShield].
///
/// Attach an instance to [AppShield.controller] to lock the app, unlock it, or
/// toggle screenshot blocking without rebuilding the widget tree.
///
/// ```dart
/// final controller = AppShieldController();
///
/// AppShield(
///   controller: controller,
///   requireAuthOnResume: true,
///   child: MyApp(),
/// );
///
/// // Later:
/// await controller.lock();
/// await controller.setScreenshotPrevention(false);
/// ```
class AppShieldController extends ChangeNotifier {
  SecureApplicationController? _secureController;
  final NoScreenshot _noScreenshot;
  bool _screenshotPreventionEnabled = false;
  bool _ownsScreenshotClaim = false;
  bool _attached = false;
  bool _locked = false;

  /// Optional hook invoked when [unlock] is called and biometric auth is needed.
  ///
  /// Should return `true` when authentication succeeds. [AppShield] wires this
  /// automatically when auth-on-resume / auth-on-launch is enabled.
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

  /// Binds this controller to a live [SecureApplicationController].
  ///
  /// Called by [AppShield]; prefer using the public lock/unlock APIs instead.
  void bind({
    required SecureApplicationController? secureController,
    required bool screenshotPreventionEnabled,
    required bool ownsScreenshotClaim,
  }) {
    _secureController = secureController;
    _screenshotPreventionEnabled = screenshotPreventionEnabled;
    _ownsScreenshotClaim = ownsScreenshotClaim;
    _attached = true;
    _locked = secureController?.locked ?? false;
    notifyListeners();
  }

  /// Clears the binding when [AppShield] is disposed.
  void unbind() {
    _secureController = null;
    _attached = false;
    notifyListeners();
  }

  /// Syncs locked state from the underlying secure controller.
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
    _locked = false;
    notifyListeners();
    return true;
  }

  /// Enables or disables screenshot / screen-recording prevention at runtime.
  ///
  /// When bound to [AppShield] that owns a prevention claim, this updates the
  /// shared [ScreenshotPrevention] counter. Otherwise it talks to [NoScreenshot]
  /// directly.
  Future<bool> setScreenshotPrevention(bool enabled) async {
    if (enabled == _screenshotPreventionEnabled) return true;

    try {
      bool result;
      if (_ownsScreenshotClaim) {
        result = enabled
            ? await ScreenshotPrevention.instance.acquire()
            : await ScreenshotPrevention.instance.release();
      } else {
        result = enabled
            ? await _noScreenshot.screenshotOff()
            : await _noScreenshot.screenshotOn();
      }
      if (result || enabled == ScreenshotPrevention.instance.isEnabled) {
        _screenshotPreventionEnabled = enabled;
        _ownsScreenshotClaim = enabled && _attached;
        notifyListeners();
        return true;
      }
      return result;
    } catch (e) {
      debugPrint('setScreenshotPrevention failed: $e');
      return false;
    }
  }
}
