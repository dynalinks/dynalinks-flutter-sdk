# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-01-21

### Fixed

- **CRITICAL**: Updated iOS SDK dependency to require minimum version 1.0.3 (`~> 1.0.3`)
  - Fixes build error: "Value of type 'DeepLinkResult.LinkData' has no member 'referrer'"
  - Previous `~> 1.0` allowed iOS SDK 1.0.2 which lacks attribution fields
  - Users should run `cd ios && pod update DynalinksSDK` after updating

## [1.0.2] - 2026-01-21

### Added

- Added attribution tracking fields to `LinkData` model:
  - `referrer` - Referrer tracking parameter (e.g., "utm_source=facebook&utm_campaign=summer")
  - `providerToken` - Apple Search Ads attribution token (pt parameter)
  - `campaignToken` - Campaign identifier for attribution (ct parameter)
- Updated README with attribution tracking examples
- iOS plugin bridge now passes attribution fields from native SDK 1.0.3
- Android plugin bridge now passes attribution fields from native SDK 1.0.1

### Changed

- Updated Android SDK dependency to 1.0.1 (adds `iosDeferredDeepLinkingEnabled` field)
- iOS SDK dependency remains at `~> 1.0` (automatically resolves to 1.0.3)

## [1.0.1] - 2026-01-21

### Fixed

- Fixed TypeError when parsing nested maps from Android platform channels
- Android platform now properly handles `Map<Object?, Object?>` to `Map<String, dynamic>` conversion for link data
- Resolves: `type '_Map<Object?, Object?>' is not a subtype of type 'Map<String, dynamic>' in type cast` error

## [1.0.0] - 2025-01-06

### Added

- Initial release of the Dynalinks Flutter SDK
- **Deferred Deep Linking**: Check for deep links that were clicked before app installation
- **Universal Links (iOS)**: Automatic handling of incoming Universal Links
- **App Links (Android)**: Automatic handling of incoming App Links
- **Manual Link Resolution**: Resolve any Dynalinks URL programmatically

### Features

- `Dynalinks.configure()` - Initialize the SDK with your API key
- `Dynalinks.checkForDeferredDeepLink()` - Check for deferred deep links on first launch
- `Dynalinks.handleDeepLink(Uri)` - Manually resolve a deep link URI
- `Dynalinks.getInitialLink()` - Get the link that launched the app (cold start)
- `Dynalinks.onDeepLinkReceived` - Stream of incoming links while app is running
- `Dynalinks.reset()` - Reset SDK state (for testing)

### Models

- `DeepLinkResult` - Result of deep link resolution with match confidence
- `LinkData` - Complete link data including deep link value, URLs, and social metadata
- `Confidence` - Match confidence level (high, medium, low)
- `DynalinksLogLevel` - SDK logging verbosity levels

### Exceptions

- `NotConfiguredException` - SDK not configured before use
- `InvalidApiKeyException` - Invalid API key provided
- `SimulatorException` - Running on iOS Simulator or Android Emulator
- `NetworkException` - Network request failed
- `ServerException` - Server returned an error
- `NoMatchException` - No matching link found
- Platform-specific exceptions for Android Install Referrer

### Platform Support

- iOS 16.0+
- Android API 21+ (Android 5.0 Lollipop)
- Flutter 3.3.0+
