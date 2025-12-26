<div align="center">

# Flutter App Shield 🚀

**A powerful & easy-to-use Flutter package** that protects your app's sensitive content from screenshots, screen recordings, and exposure in the app switcher.

[![Pub Version](https://img.shields.io/pub/v/flutter_privacy_shield?logo=dart&style=flat-square)](https://pub.dev/packages/flutter_privacy_shield)
[![Likes](https://img.shields.io/pub/likes/flutter_privacy_shield?style=flat-square)](https://pub.dev/packages/flutter_privacy_shield/score)
[![Popularity](https://img.shields.io/pub/popularity/flutter_privacy_shield?style=flat-square)](https://pub.dev/packages/flutter_privacy_shield/score)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)

</div>

---

<div align="center">

### Demo Screenshots




**Screenshot Prevention** – Android shows a black screen when trying to capture
(assets/black_screen.png)

</div>

---

## Features

- **Prevent Screenshots & Recordings** – Black screen on Android, protected on iOS (`no_screenshot`)
- **Blur in Background** – Frosted blur overlay in app switcher (`secure_application`)
- **Resume Authentication** – Require biometrics or PIN when app returns from background
- **Root/Jailbreak Detection** – Block app on compromised devices
- **Highly Customizable** – Custom locked screens, max attempts, auto-exit, and more
- **Cross-Platform** – Works seamlessly on **iOS** and **Android**

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_app_shield: ^0.1.0
```

Then run:

```bash
flutter pub get
```

### Required Configuration

**iOS** – Add this to your `Info.plist` for biometric usage description:

```xml
<key>NSFaceIDUsageDescription</key>
<string>This app uses biometric authentication to protect your sensitive data.</string>
```

**Android** – No extra permissions needed for core features.

## Usage

Just wrap your app (or any widget) with `PrivacyShield`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_app_shield/flutter_app_shield.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PrivacyShield(
      preventScreenshot: true,
      requireAuthOnResume: true,
      blockOnJailbreak: true,
      blurAmount: 25.0,
      opacity: 0.9,
      maxAuthAttempts: 3,
      exitOnMaxAttempts: false,
      child: MaterialApp(
        title: 'Secure App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Home')),
      body: const Center(
        child: Text('Your sensitive content is now fully protected! 🔒'),
      ),
    );
  }
}
```

## Customization

Fully customize the security screens and behavior:

```dart
PrivacyShield(
  // ... other options
  maxAuthAttempts: 5,
  maxAttemptsMessage: 'Too many failed attempts. App locked for security.',

  // Custom warning for rooted/jailbroken devices
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

  // Custom lock screen
  lockedBuilder: (context, controller) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_outline, size: 80, color: Colors.white),
        const SizedBox(height: 20),
        const Text(
          'Authenticate to continue',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => controller?.unlock(),
          child: const Text('Unlock with Biometrics'),
        ),
      ],
    ),
  ),

  child: MaterialApp(...),
);
```

## Development & Testing

- Test **screenshot prevention** and **root detection** only on **real devices**
- Ensure device has biometrics or PIN set up for authentication testing
- Some features (e.g., `exitOnMaxAttempts`) are disabled on Flutter Web

## Contributing

Contributions are very welcome! 🎉

- Report bugs or request features via [Issues](https://github.com/yourusername/flutter_privacy_shield/issues)
- Submit Pull Requests with improvements

## License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

---

<div align="center">
Made with ❤️ for secure Flutter apps<br>
Star this repo if you found it helpful! ⭐
</div>
