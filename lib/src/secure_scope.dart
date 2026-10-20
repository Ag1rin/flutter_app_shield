import 'package:flutter/widgets.dart';

import 'screenshot_prevention.dart';

/// Protects only a subtree from screenshots / screen recording.
///
/// Unlike [AppShield], this does not blur the app switcher or require biometric
/// auth — it only toggles native screenshot prevention while the scope is
/// mounted. Nested [SecureScope] widgets share a reference count so prevention
/// stays on until the outermost scope is disposed.
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => SecureScope(
///       child: SensitivePage(),
///     ),
///   ),
/// );
/// ```
class SecureScope extends StatefulWidget {
  /// The subtree to protect.
  final Widget child;

  /// Whether screenshot prevention is active for this scope.
  ///
  /// Default: `true`
  final bool preventScreenshot;

  /// Creates a [SecureScope].
  const SecureScope({
    super.key,
    required this.child,
    this.preventScreenshot = true,
  });

  @override
  State<SecureScope> createState() => _SecureScopeState();
}

class _SecureScopeState extends State<SecureScope> {
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _syncPrevention();
  }

  @override
  void didUpdateWidget(covariant SecureScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preventScreenshot != widget.preventScreenshot) {
      _syncPrevention();
    }
  }

  Future<void> _syncPrevention() async {
    if (widget.preventScreenshot && !_holding) {
      await ScreenshotPrevention.instance.acquire();
      _holding = true;
    } else if (!widget.preventScreenshot && _holding) {
      await ScreenshotPrevention.instance.release();
      _holding = false;
    }
  }

  @override
  void dispose() {
    if (_holding) {
      ScreenshotPrevention.instance.release();
      _holding = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
