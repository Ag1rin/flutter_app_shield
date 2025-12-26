import 'package:flutter/material.dart';
import 'package:secure_application/secure_application.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:local_auth/local_auth.dart';

/// A comprehensive privacy and security widget for Flutter apps.
/// Prevents screenshots, blurs the app in background, requires authentication
/// on resume (if enabled), and optionally blocks rooted/jailbroken devices.
class PrivacyShield extends StatefulWidget {
  /// The main app widget to protect
  final Widget child;

  /// Amount of blur applied when app is in background
  final double blurAmount;

  /// Opacity of the blur overlay
  final double opacity;

  /// Prevent screenshots and screen recording (default: true)
  final bool preventScreenshot;

  /// Require biometric/PIN authentication when returning from background
  final bool requireAuthOnResume;

  /// Block the app if device is rooted or jailbroken
  final bool blockOnJailbreak;

  const PrivacyShield({
    super.key,
    required this.child,
    this.blurAmount = 20.0,
    this.opacity = 0.8,
    this.preventScreenshot = true,
    this.requireAuthOnResume = false,
    this.blockOnJailbreak = false,
  });

  @override
  State<PrivacyShield> createState() => _PrivacyShieldState();
}

class _PrivacyShieldState extends State<PrivacyShield> {
  final _noScreenshot = NoScreenshot.instance;
  final _localAuth = LocalAuthentication();
  bool _isDeviceCompromised = false;

  @override
  void initState() {
    super.initState();
    _setupSecurity();
  }

  Future<void> _setupSecurity() async {
    // Prevent screenshots and screen recording
    if (widget.preventScreenshot) {
      await _noScreenshot.screenshotOff();
    }

    // Detect rooted/jailbroken device
    if (widget.blockOnJailbreak) {
      final bool jailbroken = await FlutterJailbreakDetection.jailbroken;
      final bool developerMode =
          await FlutterJailbreakDetection.developerMode; // Android only

      if (jailbroken || developerMode) {
        if (mounted) {
          setState(() {
            _isDeviceCompromised = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If device is compromised and blocking is enabled, show warning
    if (_isDeviceCompromised) {
      return const Material(
        color: Colors.black,
        child: Center(
          child: Text(
            'This app cannot run on rooted or jailbroken devices.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 24),
          ),
        ),
      );
    }

    return SecureApplication(
      // Require authentication on resume if enabled
      onNeedUnlock: widget.requireAuthOnResume
          ? (controller) async {
              try {
                final bool authenticated = await _localAuth.authenticate(
                  localizedReason: 'Please authenticate to access the app',
                  options: const AuthenticationOptions(
                    stickyAuth: true,
                    biometricOnly: false,
                  ),
                );

                if (authenticated) {
                  controller?.unlock();
                  return SecureApplicationAuthenticationStatus.SUCCESS;
                } else {
                  return SecureApplicationAuthenticationStatus.FAILED;
                }
              } catch (e) {
                return SecureApplicationAuthenticationStatus.FAILED;
              }
            }
          : null,
      child: SecureGate(
        blurr: widget
            .blurAmount, // Note: parameter is intentionally spelled "blurr" in the package
        opacity: widget.opacity,
        lockedBuilder: (context, controller) => Center(
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
                onPressed: () {
                  if (widget.requireAuthOnResume) {
                    controller?.unlock(); // Triggers onNeedUnlock
                  } else {
                    controller?.unlock();
                  }
                },
                child: Text(
                  widget.requireAuthOnResume ? 'Authenticate' : 'Unlock',
                ),
              ),
            ],
          ),
        ),
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    // Optionally re-enable screenshots on dispose if needed
    super.dispose();
  }
}
