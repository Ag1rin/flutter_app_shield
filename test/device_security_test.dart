import 'package:flutter_app_shield/flutter_app_shield.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceSecurityStatus.shouldBlock', () {
    const status = DeviceSecurityStatus(
      isJailbroken: true,
      isDeveloperMode: true,
    );

    test('blocks on jailbreak when enabled', () {
      expect(
        status.shouldBlock(blockOnJailbreak: true, blockOnDeveloperMode: false),
        isTrue,
      );
    });

    test('blocks on developer mode when enabled', () {
      expect(
        status.shouldBlock(blockOnJailbreak: false, blockOnDeveloperMode: true),
        isTrue,
      );
    });

    test('does not block when both flags are off', () {
      expect(
        status.shouldBlock(
          blockOnJailbreak: false,
          blockOnDeveloperMode: false,
        ),
        isFalse,
      );
    });

    test('clean device never blocks', () {
      const clean = DeviceSecurityStatus(
        isJailbroken: false,
        isDeveloperMode: false,
      );
      expect(
        clean.shouldBlock(blockOnJailbreak: true, blockOnDeveloperMode: true),
        isFalse,
      );
    });
  });
}
