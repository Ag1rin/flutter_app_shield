import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// Result of a device integrity check.
class DeviceSecurityStatus {
  /// Whether the device is rooted (Android) or jailbroken (iOS).
  final bool isJailbroken;

  /// Whether Android developer / USB debugging mode is enabled.
  ///
  /// Always `false` on non-Android platforms.
  final bool isDeveloperMode;

  /// Creates a [DeviceSecurityStatus].
  const DeviceSecurityStatus({
    required this.isJailbroken,
    required this.isDeveloperMode,
  });

  /// Whether the device should be blocked given the caller's policy flags.
  bool shouldBlock({
    required bool blockOnJailbreak,
    required bool blockOnDeveloperMode,
  }) {
    if (blockOnJailbreak && isJailbroken) return true;
    if (blockOnDeveloperMode && isDeveloperMode) return true;
    return false;
  }
}

/// Checks device integrity (root/jailbreak and Android developer mode).
class DeviceSecurity {
  /// Creates a [DeviceSecurity] helper.
  const DeviceSecurity();

  /// Probes the current device. Returns a safe default on web / unsupported hosts.
  Future<DeviceSecurityStatus> check() async {
    if (kIsWeb) {
      return const DeviceSecurityStatus(
        isJailbroken: false,
        isDeveloperMode: false,
      );
    }

    try {
      final bool jailbroken = await FlutterJailbreakDetection.jailbroken;
      bool developerMode = false;
      if (!kIsWeb && Platform.isAndroid) {
        developerMode = await FlutterJailbreakDetection.developerMode;
      }
      return DeviceSecurityStatus(
        isJailbroken: jailbroken,
        isDeveloperMode: developerMode,
      );
    } catch (e) {
      debugPrint('DeviceSecurity check failed: $e');
      return const DeviceSecurityStatus(
        isJailbroken: false,
        isDeveloperMode: false,
      );
    }
  }
}
