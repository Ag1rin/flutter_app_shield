import 'dart:async';

import 'package:flutter/widgets.dart';

/// Watches pointer and keyboard activity and fires [onTimeout] after idle time.
class InactivityWatcher {
  Timer? _timer;
  Duration? _timeout;
  VoidCallback? _onTimeout;
  bool _enabled = false;

  /// Whether the watcher is actively tracking inactivity.
  bool get isEnabled => _enabled;

  /// Current inactivity timeout, or `null` when disabled.
  Duration? get timeout => _timeout;

  /// Configures and starts watching.
  ///
  /// Passing a `null` [timeout] disables the watcher.
  void configure({
    required Duration? timeout,
    required VoidCallback onTimeout,
  }) {
    _onTimeout = onTimeout;
    _timeout = timeout;
    if (timeout == null) {
      stop();
      return;
    }
    _enabled = true;
    ping();
  }

  /// Resets the idle timer after user activity.
  void ping() {
    if (!_enabled || _timeout == null) return;
    _timer?.cancel();
    _timer = Timer(_timeout!, () {
      _onTimeout?.call();
    });
  }

  /// Stops the watcher without clearing the configured callback.
  void stop() {
    _enabled = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Cancels timers and clears configuration.
  void dispose() {
    stop();
    _onTimeout = null;
    _timeout = null;
  }
}

/// Wraps [child] and reports pointer / keyboard activity to [watcher].
class InactivityListener extends StatelessWidget {
  /// The inactivity watcher that receives activity pings.
  final InactivityWatcher watcher;

  /// The subtree to observe.
  final Widget child;

  /// Creates an [InactivityListener].
  const InactivityListener({
    super.key,
    required this.watcher,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => watcher.ping(),
      onPointerMove: (_) => watcher.ping(),
      onPointerSignal: (_) => watcher.ping(),
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, __) {
          watcher.ping();
          return KeyEventResult.ignored;
        },
        child: child,
      ),
    );
  }
}
