## [0.1.6]

### Changed
- Widened `no_screenshot` constraint to `>=1.2.0 <3.0.0` so the latest stable (`2.x`) is supported (restores the missing 10 pub.dev dependency points)
- Added `repository`, `issue_tracker`, and `topics` to `pubspec.yaml`
- Updated GitHub links to the renamed repository (`flutter_app_shield`)
- Added library-level dartdoc comment
- Fixed README examples to use `AppShield` instead of the old `PrivacyShield` name

## [0.1.5]

### Changed
- Updated `no_screenshot` dependency constraint to `^1.1.0` to support the latest stable release
- Replaced broken `Popularity` badge in README with `Pub Points` badge (popularity metric was removed from pub.dev)

## [0.1.4] 

### Changed
- Updated `local_auth` dependency to support version 3.0.0+
- Refactored authentication logic to match the latest `local_auth` API changes:
  - Removed deprecated `options: AuthenticateOptions(...)`
  - Passed `stickyAuth` and `biometricOnly` directly as named parameters to `authenticate()`

### Fixed
- Resolved compilation errors caused by breaking changes in `local_auth` 3.0.0
- Ensured compatibility with the most recent stable version of `local_auth`

This update maintains full functionality while keeping the package up-to-date with dependency changes.

## [0.1.3] 

### Added
- Full DartDoc documentation for all public APIs (including class, constructor, and parameters)
- Comprehensive example app in `example/` folder demonstrating all features

### Changed
- Renamed main widget from `PrivacyShield` to `AppShield` for better alignment with package name
- Updated all dependencies to their latest stable versions:
  - `secure_application` to latest
  - `no_screenshot` to latest
  - `flutter_jailbreak_detection` to latest
  - `local_auth` to latest

### Fixed
- Minor code cleanups and improvements for better readability and performance

## [0.1.2] 

### Added
- Added runnable `example/` folder with a complete demo app

### Changed
- Major README improvements: better formatting, clearer installation/usage instructions, customization examples, and testing tips

## [0.1.1] 

### Changed
- Updated README with detailed usage, features, and configuration examples
- Improved documentation and structure for better user experience

## [0.1.0] 

### Added
- Initial release
- Core features:
  - Screenshot and screen recording prevention
  - Background blur in app switcher
  - Optional biometric/PIN authentication on resume
  - Optional block on rooted/jailbroken devices
  - Customizable lock and compromised device screens
  - Max authentication attempts with optional app exit
