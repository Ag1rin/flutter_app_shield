import 'package:flutter/services.dart';
import 'package:flutter_app_shield/flutter_app_shield.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_application/secure_application.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureChannel = MethodChannel('secure_application');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, null);
  });

  group('AppShieldController', () {
    test('starts detached and unlocked', () {
      final controller = AppShieldController();
      expect(controller.isAttached, isFalse);
      expect(controller.isLocked, isFalse);
      expect(controller.isScreenshotPreventionEnabled, isFalse);
    });

    test('bind and lock/unlock without authenticate hook', () async {
      final controller = AppShieldController();
      final secure = SecureApplicationController(SecureApplicationState());

      controller.bind(
        secureController: secure,
        screenshotPreventionEnabled: false,
        ownsScreenshotClaim: false,
      );

      expect(controller.isAttached, isTrue);

      await controller.lock();
      expect(controller.isLocked, isTrue);
      expect(secure.locked, isTrue);

      final unlocked = await controller.unlock();
      expect(unlocked, isTrue);
      expect(controller.isLocked, isFalse);
      expect(secure.locked, isFalse);

      controller.unbind();
      expect(controller.isAttached, isFalse);
    });

    test('unlock fails when authenticate returns false', () async {
      final controller = AppShieldController();
      final secure = SecureApplicationController(SecureApplicationState());

      controller.bind(
        secureController: secure,
        screenshotPreventionEnabled: false,
        ownsScreenshotClaim: false,
      );
      controller.authenticate = () async => false;

      await controller.lock();
      final unlocked = await controller.unlock();
      expect(unlocked, isFalse);
      expect(controller.isLocked, isTrue);
    });

    test('syncLocked notifies listeners', () {
      final controller = AppShieldController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.syncLocked(true);
      expect(controller.isLocked, isTrue);
      expect(notifications, 1);

      controller.syncLocked(true);
      expect(notifications, 1);
    });
  });
}
