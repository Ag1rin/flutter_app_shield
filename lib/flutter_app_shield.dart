/// Flutter App Shield — screenshot prevention, background blur, and auth guards.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:secure_application/secure_application.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:local_auth/local_auth.dart';

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
/// - Optional biometric/PIN authentication when resuming the app
/// - Optional block on rooted or jailbroken devices
/// - Customizable lock screens and error handling
///
/// ### Example
/// ```dart
/// void main() {
///   runApp(
///     AppShield(
///       preventScreenshot: true,
///       requireAuthOnResume: true,
///       blockOnJailbreak: true,
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
///
/// See the package README and example/ folder for full usage and customization.
class AppShield extends StatefulWidget {
  /// The main widget to protect with security features.
  ///
  /// This is typically your entire [MaterialApp] or [CupertinoApp].
  final Widget child;

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

  /// Whether to block the app entirely if the device is rooted (Android) or
  /// jailbroken (iOS).
  ///
  /// Default: false
  final bool blockOnJailbreak;

  /// Maximum number of failed authentication attempts before showing an error.
  ///
  /// Default: 3
  final int maxAuthAttempts;

  /// Custom widget to display when the device is detected as compromised
  /// (rooted/jailbroken) and [blockOnJailbreak] is true.
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

  /// Creates an [AppShield] security wrapper.
  ///
  /// Use the various parameters to enable and configure security features.
  const AppShield({
    super.key,
    required this.child,
    this.blurAmount = 20.0,
    this.opacity = 0.8,
    this.preventScreenshot = true,
    this.requireAuthOnResume = false,
    this.blockOnJailbreak = false,
    this.maxAuthAttempts = 3,
    this.compromisedDeviceBuilder,
    this.lockedBuilder,
    this.exitOnMaxAttempts = false,
    this.maxAttemptsMessage =
        'Too many failed attempts. Please try again later.',
  });

  @override
  State<AppShield> createState() => _AppShieldState();
}

class _AppShieldState extends State<AppShield> {
  final _noScreenshot = NoScreenshot.instance;
  final _localAuth = LocalAuthentication();

  bool _isDeviceCompromised = false;
  late Future<void> _securityFuture;

  int _authAttempts = 0;
  bool _authFailed = false;

  @override
  void initState() {
    super.initState();
    _securityFuture = _setupSecurity();
  }

  /// Initializes security features: screenshot prevention and root/jailbreak detection.
  Future<void> _setupSecurity() async {
    if (widget.preventScreenshot) {
      await _noScreenshot.screenshotOff();
    }

    if (widget.blockOnJailbreak) {
      final bool jailbroken = await FlutterJailbreakDetection.jailbroken;
      bool developerMode = false;
      if (Platform.isAndroid) {
        developerMode = await FlutterJailbreakDetection.developerMode;
      }

      if (jailbroken || developerMode) {
        _isDeviceCompromised = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _securityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_isDeviceCompromised) {
          return widget.compromisedDeviceBuilder ??
              Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Text(
                    'This app cannot run on rooted or jailbroken devices.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 24),
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

        return SecureApplication(
          onNeedUnlock: widget.requireAuthOnResume
              ? (controller) async {
                  try {
                    final bool authenticated = await _localAuth.authenticate(
                      localizedReason: 'Please authenticate to access the app',
                      biometricOnly: false,
                    );

                    if (authenticated) {
                      _authAttempts = 0;
                      controller?.unlock();
                      return SecureApplicationAuthenticationStatus.SUCCESS;
                    } else {
                      _authAttempts++;
                      if (_authAttempts >= widget.maxAuthAttempts) {
                        if (mounted) setState(() => _authFailed = true);
                        if (widget.exitOnMaxAttempts && !kIsWeb) exit(0);
                      }
                      return SecureApplicationAuthenticationStatus.FAILED;
                    }
                  } catch (e) {
                    debugPrint('Authentication error: $e');
                    _authAttempts++;
                    if (_authAttempts >= widget.maxAuthAttempts) {
                      if (mounted) setState(() => _authFailed = true);
                      if (widget.exitOnMaxAttempts && !kIsWeb) exit(0);
                    }
                    return SecureApplicationAuthenticationStatus.FAILED;
                  }
                }
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
                        onPressed: () => controller?.unlock(),
                        child: Text(
                          widget.requireAuthOnResume
                              ? 'Authenticate'
                              : 'Unlock',
                        ),
                      ),
                    ],
                  ),
                ),
            child: widget.child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (widget.preventScreenshot) {
      _noScreenshot.screenshotOn();
    }
    super.dispose();
  }
}
