# Flutter Privacy Shield 🚀

A simple Flutter package that prevents screenshots, blocks screen recording, and blurs sensitive content when the app is in background or app switcher.

## Features
- Prevent screenshots (black screen on Android)
- Blur screen in background/app switcher
- Easy to use: Just wrap your app with one widget
- **Screenshot Prevention**: Uses `no_screenshot` to disable screenshots and recordings.
- **Background Blur**: Blurs the app preview in the app switcher using `secure_application`.
- **Resume Authentication**: Requires local authentication (biometrics/PIN) when the app resumes.
- **Jailbreak/Root Detection**: Blocks access on compromised devices using `flutter_jailbreak_detection`.
- **Customizable**: Options for max auth attempts, custom builders for locked and compromised screens, and more.
- **Cross-Platform**: Works on iOS and Android.

## Installation
Add to pubspec.yaml:
```yaml
dependencies:
  flutter_privacy_shield: ^0.1.0
```

Then run `flutter pub get`.

Note: This package depends on:
- `secure_application`
- `no_screenshot`
- `flutter_jailbreak_detection`
- `local_auth`

Make sure to configure platform-specific setup:
- For iOS: Add NSFaceIDUsageDescription to Info.plist.
- For Android: Add permissions if needed for biometrics.

## Usage

Wrap your main app widget with `PrivacyShield`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_privacy_shield/flutter_privacy_shield.dart';  

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
      exitOnMaxAttempts: true,  // Optionally exit app after max attempts
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
      body: const Center(child: Text('Your secure content here')),
    );
  }
}
```

### Customization

- **compromisedDeviceBuilder**: Provide a custom widget for the compromised device screen.
- **lockedBuilder**: Custom builder for the locked screen.
- **maxAttemptsMessage**: Custom message when max attempts exceeded.
- **exitOnMaxAttempts**: Set to true to exit the app after max failed attempts (non-web only).

Example with custom builders:

```dart
PrivacyShield(
  // ... other params
  compromisedDeviceBuilder: Scaffold(
    body: Center(child: Text('Custom Warning: Device is compromised!')),
  ),
  lockedBuilder: (context, controller) => Center(
    child: Column(
      children: [
        Text('Custom Locked Screen'),
        ElevatedButton(
          onPressed: () => controller?.unlock(),
          child: Text('Try Again'),
        ),
      ],
    ),
  ),
);
```

## Development and Testing

- Test on physical devices for jailbreak/root detection.
- For authentication, ensure device has biometrics or PIN set up.
- On web, some features like exit(0) are disabled.

## Contributing

Feel free to fork and submit PRs. Issues welcome!

## License

MIT License. See LICENSE file.