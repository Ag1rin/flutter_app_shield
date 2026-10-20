/// Flutter App Shield — screenshot prevention, background blur, and auth guards.
library;

export 'package:secure_application/secure_application.dart'
    show SecureApplicationController, SecureApplicationAuthenticationStatus;

export 'src/app_shield.dart';
export 'src/app_shield_controller.dart';
export 'src/capture_detector.dart' show CaptureEvent, CaptureDetector;
export 'src/device_security.dart' show DeviceSecurity, DeviceSecurityStatus;
export 'src/secure_scope.dart';
