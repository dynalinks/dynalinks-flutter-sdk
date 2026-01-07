# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
