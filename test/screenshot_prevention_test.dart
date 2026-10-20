import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app_shield/src/screenshot_prevention.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.flutterplaza.no_screenshot_methods');

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => true);
    await ScreenshotPrevention.instance.reset();
  });

  tearDown(() async {
    await ScreenshotPrevention.instance.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('ScreenshotPrevention reference counting', () {
    test('holders increment and decrement', () async {
      final prevention = ScreenshotPrevention.instance;
      expect(prevention.holders, 0);

      await prevention.acquire();
      expect(prevention.holders, 1);
      expect(prevention.isEnabled, isTrue);

      await prevention.acquire();
      expect(prevention.holders, 2);

      await prevention.release();
      expect(prevention.holders, 1);
      expect(prevention.isEnabled, isTrue);

      await prevention.release();
      expect(prevention.holders, 0);
      expect(prevention.isEnabled, isFalse);
    });

    test('release below zero stays at zero', () async {
      final prevention = ScreenshotPrevention.instance;
      await prevention.release();
      expect(prevention.holders, 0);
    });
  });
}
