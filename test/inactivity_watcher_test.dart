import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app_shield/src/inactivity_watcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InactivityWatcher', () {
    test('fires onTimeout after idle duration', () async {
      final watcher = InactivityWatcher();
      var fired = 0;

      watcher.configure(
        timeout: const Duration(milliseconds: 50),
        onTimeout: () => fired++,
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(fired, 1);

      watcher.dispose();
    });

    test('ping resets the timer', () async {
      final watcher = InactivityWatcher();
      var fired = 0;

      watcher.configure(
        timeout: const Duration(milliseconds: 60),
        onTimeout: () => fired++,
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));
      watcher.ping();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(fired, 0);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(fired, 1);

      watcher.dispose();
    });

    test('null timeout disables watcher', () async {
      final watcher = InactivityWatcher();
      var fired = 0;

      watcher.configure(
        timeout: const Duration(milliseconds: 30),
        onTimeout: () => fired++,
      );
      watcher.configure(timeout: null, onTimeout: () => fired++);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(fired, 0);
      expect(watcher.isEnabled, isFalse);

      watcher.dispose();
    });
  });
}
