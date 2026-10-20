<div align="center">

# Flutter App Shield

**A powerful Flutter security wrapper** for screenshot/recording prevention, capture detection, biometric lock, inactivity auto-lock, and per-screen protection.

[![Pub Version](https://img.shields.io/pub/v/flutter_app_shield?logo=dart&style=flat-square)](https://pub.dev/packages/flutter_app_shield)
[![Likes](https://img.shields.io/pub/likes/flutter_app_shield?style=flat-square)](https://pub.dev/packages/flutter_app_shield/score)
[![Pub Points](https://img.shields.io/pub/points/flutter_app_shield?style=flat-square)](https://pub.dev/packages/flutter_app_shield/score)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)

</div>

## Features

- **Prevent Screenshots & Recordings** – Native prevention via `no_screenshot`
- **Capture Detection** – Callbacks when a screenshot or recording starts/stops
- **Blur in Background** – Frosted overlay in the app switcher (`secure_application`)
- **Resume / Launch Auth** – Require biometrics or PIN on resume and/or first launch
- **Inactivity Auto-Lock** – Lock after a configurable idle timeout
- **Runtime Controller** – Lock, unlock, and toggle prevention without rebuilding
- **SecureScope** – Protect only a sensitive page/subtree (reference-counted)
- **Root / Jailbreak & Developer Mode** – Separate policy flags
- **Highly Customizable** – Custom lock screens, max attempts, exit-on-fail, and more

## Installation

```yaml
dependencies:
  flutter_app_shield: ^0.2.0
```

```bash
flutter pub get
```

### Required Configuration

**iOS** – Add to `Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>This app uses biometric authentication to protect your sensitive data.</string>
```

**Android** – No extra permissions needed for core features.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_app_shield/flutter_app_shield.dart';

void main() {
  runApp(
    AppShield(
      preventScreenshot: true,
      requireAuthOnResume: true,
      requireAuthOnLaunch: false,
      inactivityTimeout: const Duration(minutes: 1),
      blockOnJailbreak: true,
      blockOnDeveloperMode: false,
      listenToCaptureEvents: true,
      onScreenshot: (e) => debugPrint('Screenshot at ${e.timestamp}'),
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
}
```

## Runtime controller

```dart
final controller = AppShieldController();

AppShield(
  controller: controller,
  requireAuthOnResume: true,
  child: MyApp(),
);

// Later:
await controller.lock();
await controller.unlock(); // runs biometric when wired by AppShield
await controller.setScreenshotPrevention(false);
print(controller.isLocked);
```

## Per-screen protection

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SecureScope(
      child: SensitivePage(),
    ),
  ),
);
```

Nested `SecureScope` / `AppShield` prevention claims share a reference count, so protection stays on until the last holder is disposed.

## Customization

```dart
AppShield(
  maxAuthAttempts: 5,
  maxAttemptsMessage: 'Too many failed attempts. App locked for security.',
  authLocalizedReason: 'Unlock to continue',
  compromisedDeviceBuilder: const Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: Text(
        'This app cannot run on rooted or jailbroken devices.',
        style: TextStyle(color: Colors.red, fontSize: 20),
        textAlign: TextAlign.center,
      ),
    ),
  ),
  lockedBuilder: (context, secureController) => Center(
    child: ElevatedButton(
      onPressed: () => secureController?.unlock(),
      child: const Text('Unlock'),
    ),
  ),
  child: MaterialApp(...),
);
```

## Breaking change in 0.2.0

`blockOnJailbreak: true` no longer blocks Android developer mode by itself.
Use `blockOnDeveloperMode: true` if you need that behavior.

## Development & Testing

- Test screenshot prevention and root detection on **real devices**
- Ensure biometrics or a device PIN is set up for auth testing
- `exitOnMaxAttempts` is disabled on Flutter Web

## Contributing

Contributions are welcome.

- Report bugs or request features via [Issues](https://github.com/Ag1rin/flutter_app_shield/issues)
- Submit Pull Requests with improvements

## License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.
