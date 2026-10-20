import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:secure_application/secure_application.dart';

import 'app_shield_controller.dart';
import 'capture_detector.dart';
import 'device_security.dart';
import 'inactivity_watcher.dart';
import 'screenshot_prevention.dart';

/// A powerful and easy-to-use security wrapper for Flutter apps.
///
/// [AppShield] protects your app from screenshots, screen recordings, exposure
/// in the app switcher, and unauthorized access on compromised devices.
///
/// Simply wrap your main app widget (or any part of your UI) with [AppShield]
/// to enable comprehensive privacy and security features.
///
/// ### Key Features
/// - Prevents screenshots and screen recordings
/// - Blurs app preview when in background (app switcher)
/// - Optional biometric/PIN authentication on resume and/or launch
/// - Optional inactivity auto-lock
/// - Screenshot / screen-recording detection callbacks
/// - Runtime control via [AppShieldController]
/// - Optional block on rooted/jailbroken devices and Android developer mode
///
/// ### Example
/// ```dart
/// void main() {
///   runApp(
///     AppShield(
///       preventScreenshot: true,
///       requireAuthOnResume: true,
///       requireAuthOnLaunch: true,
///       inactivityTimeout: const Duration(minutes: 1),
///       blockOnJailbreak: true,
///       listenToCaptureEvents: true,
///       onScreenshot: (e) => debugPrint('Screenshot at ${e.timestamp}'),
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
class AppShield extends StatefulWidget {
  /// The main widget to protect with security features.
  ///
  /// This is typically your entire [MaterialApp] or [CupertinoApp].
  final Widget child;

  /// Optional runtime controller for lock / unlock / screenshot toggles.
  final AppShieldController? controller;

  /// Amount of blur applied when the app is in the background.
  ///
  /// Higher values create stronger blur. Default: 20.0
  final double blurAmount;

  /// Opacity of the blur overlay in the app switcher.
  ///
  /// Range: 0.0 (transparent) to 1.0 (opaque). Default: 0.8
  final double opacity;

  /// Whether to prevent screenshots and screen recordings.
  ///
  /// Default: true
  final bool preventScreenshot;

  /// Whether to require biometric or PIN authentication when the app resumes
  /// from background.
  ///
  /// Default: false
  final bool requireAuthOnResume;

  /// Whether to require biometric or PIN authentication when the app first
  /// launches (after security setup completes).
  ///
  /// Default: false
  final bool requireAuthOnLaunch;

  /// Locks the app after this duration of user inactivity.
  ///
  /// Pass `null` (default) to disable inactivity auto-lock.
  final Duration? inactivityTimeout;

  /// Whether to block the app entirely if the device is rooted (Android) or
  /// jailbroken (iOS).
  ///
  /// Does **not** include Android developer mode — use [blockOnDeveloperMode]
  /// for that. Default: false
  final bool blockOnJailbreak;

  /// Whether to block the app when Android developer / USB debugging mode is on.
  ///
  /// Ignored on non-Android platforms. Default: false
  final bool blockOnDeveloperMode;

  /// Maximum number of failed authentication attempts before showing an error.
  ///
  /// Default: 3
  final int maxAuthAttempts;

  /// Custom widget to display when the device is detected as compromised
  /// and blocking is enabled.
  ///
  /// If null, a default warning screen is shown.
  final Widget? compromisedDeviceBuilder;

  /// Custom builder for the locked screen shown when authentication is required.
  ///
  /// If null, a default lock screen with icon and button is provided.
  final Widget Function(
    BuildContext context,
    SecureApplicationController? controller,
  )?
  lockedBuilder;

  /// Whether to force-close the app after exceeding [maxAuthAttempts].
  ///
  /// Only works on native platforms (not web). Default: false
  final bool exitOnMaxAttempts;

  /// Message to display when maximum authentication attempts are exceeded.
  ///
  /// Default: 'Too many failed attempts. Please try again later.'
  final String maxAttemptsMessage;

  /// Reason string shown in the system biometric / PIN prompt.
  final String authLocalizedReason;

  /// Whether to listen for screenshot and screen-recording events.
  ///
  /// Default: false
  final bool listenToCaptureEvents;

  /// Called when a screenshot is detected (requires [listenToCaptureEvents]).
  final void Function(CaptureEvent event)? onScreenshot;

  /// Called when screen recording starts (requires [listenToCaptureEvents]).
  final void Function(CaptureEvent event)? onScreenRecordingStarted;

  /// Called when screen recording stops (requires [listenToCaptureEvents]).
  final void Function(CaptureEvent event)? onScreenRecordingStopped;

  /// Optional custom loading widget shown while security setup runs.
  final Widget? loadingBuilder;

  /// Creates an [AppShield] security wrapper.
  const AppShield({
    super.key,
    required this.child,
    this.controller,
    this.blurAmount = 20.0,
    this.opacity = 0.8,
    this.preventScreenshot = true,
    this.requireAuthOnResume = false,
    this.requireAuthOnLaunch = false,
    this.inactivityTimeout,
    this.blockOnJailbreak = false,
    this.blockOnDeveloperMode = false,
    this.maxAuthAttempts = 3,
    this.compromisedDeviceBuilder,
    this.lockedBuilder,
    this.exitOnMaxAttempts = false,
    this.maxAttemptsMessage =
        'Too many failed attempts. Please try again later.',
    this.authLocalizedReason = 'Please authenticate to access the app',
    this.listenToCaptureEvents = false,
    this.onScreenshot,
    this.onScreenRecordingStarted,
    this.onScreenRecordingStopped,
    this.loadingBuilder,
  });

  @override
  State<AppShield> createState() => _AppShieldState();
}

class _AppShieldState extends State<AppShield> {
  final _localAuth = LocalAuthentication();
  final _deviceSecurity = const DeviceSecurity();
  final _captureDetector = CaptureDetector();
  final _inactivityWatcher = InactivityWatcher();
  late final SecureApplicationController _secureController;

  bool _isDeviceCompromised = false;
  bool _ownsScreenshotClaim = false;
  late Future<void> _securityFuture;

  int _authAttempts = 0;
  bool _authFailed = false;
  bool _launchAuthPending = false;
  bool _launchAuthStarted = false;

  AppShieldController? _boundController;

  bool get _needsAuth =>
      widget.requireAuthOnResume ||
      widget.requireAuthOnLaunch ||
      widget.inactivityTimeout != null;

  @override
  void initState() {
    super.initState();
    _secureController = SecureApplicationController(SecureApplicationState());
    _secureController.addListener(_onSecureChanged);
    _launchAuthPending = widget.requireAuthOnLaunch;
    _securityFuture = _setupSecurity();
    _wireController(widget.controller);
    _configureInactivity();
  }

  void _onSecureChanged() {
    _boundController?.syncLocked(_secureController.locked);
  }

  @override
  void didUpdateWidget(covariant AppShield oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _wireController(widget.controller, previous: oldWidget.controller);
    }
    if (oldWidget.inactivityTimeout != widget.inactivityTimeout) {
      _configureInactivity();
    }
    if (oldWidget.listenToCaptureEvents != widget.listenToCaptureEvents ||
        oldWidget.onScreenshot != widget.onScreenshot ||
        oldWidget.onScreenRecordingStarted != widget.onScreenRecordingStarted ||
        oldWidget.onScreenRecordingStopped != widget.onScreenRecordingStopped) {
      _syncCaptureListening();
    }
    if (oldWidget.preventScreenshot != widget.preventScreenshot) {
      _syncScreenshotPrevention(widget.preventScreenshot);
    }
  }

  void _wireController(
    AppShieldController? next, {
    AppShieldController? previous,
  }) {
    if (previous != null && previous != next) {
      previous.authenticate = null;
      previous.unbind();
    }
    _boundController = next;
    _rebindController();
  }

  void _rebindController() {
    final next = _boundController;
    if (next == null) return;
    next.authenticate = _authenticateBiometric;
    next.bind(
      secureController: _secureController,
      screenshotPreventionEnabled: _ownsScreenshotClaim,
      ownsScreenshotClaim: _ownsScreenshotClaim,
    );
  }

  void _configureInactivity() {
    _inactivityWatcher.configure(
      timeout: widget.inactivityTimeout,
      onTimeout: () {
        if (!mounted) return;
        _secureController.lock();
      },
    );
  }

  Future<void> _setupSecurity() async {
    if (widget.preventScreenshot) {
      await ScreenshotPrevention.instance.acquire();
      _ownsScreenshotClaim = true;
    }

    if (widget.blockOnJailbreak || widget.blockOnDeveloperMode) {
      final status = await _deviceSecurity.check();
      _isDeviceCompromised = status.shouldBlock(
        blockOnJailbreak: widget.blockOnJailbreak,
        blockOnDeveloperMode: widget.blockOnDeveloperMode,
      );
    }

    await _syncCaptureListening();
    _rebindController();
  }

  Future<void> _syncCaptureListening() async {
    _captureDetector.onScreenshot = widget.onScreenshot;
    _captureDetector.onScreenRecordingStarted = widget.onScreenRecordingStarted;
    _captureDetector.onScreenRecordingStopped = widget.onScreenRecordingStopped;

    if (widget.listenToCaptureEvents) {
      await _captureDetector.start();
    } else {
      await _captureDetector.stop();
    }
  }

  Future<void> _syncScreenshotPrevention(bool enabled) async {
    if (enabled && !_ownsScreenshotClaim) {
      await ScreenshotPrevention.instance.acquire();
      _ownsScreenshotClaim = true;
    } else if (!enabled && _ownsScreenshotClaim) {
      await ScreenshotPrevention.instance.release();
      _ownsScreenshotClaim = false;
    }
    _rebindController();
  }

  Future<bool> _authenticateBiometric() async {
    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: widget.authLocalizedReason,
        biometricOnly: false,
      );
      if (authenticated) {
        _authAttempts = 0;
        return true;
      }
      await _handleAuthFailure();
      return false;
    } catch (e) {
      debugPrint('Authentication error: $e');
      await _handleAuthFailure();
      return false;
    }
  }

  Future<void> _handleAuthFailure() async {
    _authAttempts++;
    if (_authAttempts >= widget.maxAuthAttempts) {
      if (mounted) setState(() => _authFailed = true);
      if (widget.exitOnMaxAttempts && !kIsWeb) {
        exit(0);
      }
    }
  }

  Future<SecureApplicationAuthenticationStatus> _onNeedUnlock(
    SecureApplicationController? controller,
  ) async {
    final bool ok = await _authenticateBiometric();
    if (ok) {
      controller?.authSuccess(unlock: true);
      _inactivityWatcher.ping();
      return SecureApplicationAuthenticationStatus.SUCCESS;
    }
    return SecureApplicationAuthenticationStatus.FAILED;
  }

  void _maybeAuthOnLaunch() {
    if (!_launchAuthPending || _launchAuthStarted) return;
    _launchAuthStarted = true;
    _launchAuthPending = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _secureController.lock();
      if (_needsAuth) {
        await _onNeedUnlock(_secureController);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _securityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder ??
              const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (_isDeviceCompromised) {
          return widget.compromisedDeviceBuilder ??
              const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Text(
                    'This app cannot run on rooted or jailbroken devices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 24),
                  ),
                ),
              );
        }

        if (_authFailed) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                widget.maxAttemptsMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 24),
              ),
            ),
          );
        }

        _maybeAuthOnLaunch();

        Widget content = SecureApplication(
          secureApplicationController: _secureController,
          onNeedUnlock:
              widget.requireAuthOnResume ||
                  widget.requireAuthOnLaunch ||
                  widget.inactivityTimeout != null
              ? _onNeedUnlock
              : null,
          child: SecureGate(
            blurr: widget.blurAmount,
            opacity: widget.opacity,
            lockedBuilder:
                widget.lockedBuilder ??
                (context, controller) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 80, color: Colors.white),
                      const SizedBox(height: 20),
                      const Text(
                        'App is locked',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (_needsAuth) {
                            await _onNeedUnlock(controller);
                          } else {
                            controller?.unlock();
                          }
                        },
                        child: Text(_needsAuth ? 'Authenticate' : 'Unlock'),
                      ),
                    ],
                  ),
                ),
            child: widget.child,
          ),
        );

        if (widget.inactivityTimeout != null) {
          content = InactivityListener(
            watcher: _inactivityWatcher,
            child: content,
          );
        }

        return content;
      },
    );
  }

  @override
  void dispose() {
    _secureController.removeListener(_onSecureChanged);
    _inactivityWatcher.dispose();
    _captureDetector.dispose();
    if (_ownsScreenshotClaim) {
      ScreenshotPrevention.instance.release();
      _ownsScreenshotClaim = false;
    }
    _boundController?.authenticate = null;
    _boundController?.unbind();
    super.dispose();
  }
}
