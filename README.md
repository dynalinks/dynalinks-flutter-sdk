# Dynalinks Flutter SDK

The official Flutter SDK for [Dynalinks](https://dynalinks.app) - deferred deep linking and attribution for iOS and Android apps.

[![pub package](https://img.shields.io/pub/v/dynalinks.svg)](https://pub.dev/packages/dynalinks)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Features

- **Deferred Deep Linking**: Track users who click links before installing your app
- **Universal Links / App Links**: Handle incoming deep links automatically
- **Cross-Platform**: Single API for both iOS and Android
- **Type-Safe**: Full Dart type safety with comprehensive error handling

## Requirements

- Flutter 3.3.0 or later
- iOS 16.0 or later
- Android API 21 or later

## Installation

Add `dynalinks` to your `pubspec.yaml`:

```yaml
dependencies:
  dynalinks: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### iOS Setup

1. **Register your iOS app** in the [Dynalinks Console](https://dynalinks.app/console):
   - Bundle Identifier (from Xcode project settings)
   - Team ID (from Apple Developer account)
   - App Store ID (from your app's App Store URL)

2. **Configure Associated Domains** in Xcode:
   - Open your iOS project > Signing & Capabilities
   - Add the "Associated Domains" capability
   - Add your domain: `applinks:yourproject.dynalinks.app`

See the [iOS integration guide](https://docs.dynalinks.app/integrations/ios.html) for detailed instructions.

### Android Setup

1. **Register your Android app** in the [Dynalinks Console](https://dynalinks.app/console):
   - Package identifier (from `build.gradle` applicationId)
   - SHA-256 certificate fingerprint (run `./gradlew signingReport`)

2. **Add JitPack repository** to your project's `settings.gradle.kts`:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
```

3. **Add intent filter** to your `AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTask">

    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="https"
            android:host="yourproject.dynalinks.app" />
    </intent-filter>
</activity>
```

See the [Android integration guide](https://docs.dynalinks.app/integrations/android.html) for detailed instructions.

## Usage

### Initialize the SDK

Configure the SDK as early as possible in your app's lifecycle:

```dart
import 'package:dynalinks/dynalinks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Dynalinks.configure(
    clientAPIKey: 'your-client-api-key',
    logLevel: DynalinksLogLevel.debug, // Use .error in production
  );

  runApp(const MyApp());
}
```

### Check for Deferred Deep Links

Check if the user came from a Dynalinks link before installing:

```dart
Future<void> checkDeferredDeepLink() async {
  try {
    final result = await Dynalinks.checkForDeferredDeepLink();

    if (result.matched && result.link != null) {
      // User came from a deep link - navigate accordingly
      final deepLinkValue = result.link!.deepLinkValue;
      if (deepLinkValue != null) {
        navigateTo(deepLinkValue);
      }
    }
  } on SimulatorException {
    // Running on simulator - deferred deep linking not available
  } on DynalinksException catch (e) {
    print('Error: ${e.message}');
  }
}
```

### Handle Incoming Deep Links

Listen for links that open your app while it's running:

```dart
class _MyAppState extends State<MyApp> {
  StreamSubscription<DeepLinkResult>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialLink();
    _listenForLinks();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialLink() async {
    // Check for cold start link
    final initialLink = await Dynalinks.getInitialLink();
    if (initialLink != null && initialLink.matched) {
      _handleResult(initialLink);
    }
  }

  void _listenForLinks() {
    _subscription = Dynalinks.onDeepLinkReceived.listen(_handleResult);
  }

  void _handleResult(DeepLinkResult result) {
    if (result.matched && result.link?.deepLinkValue != null) {
      // Navigate to the deep link destination
      Navigator.pushNamed(context, result.link!.deepLinkValue!);
    }
  }
}
```

### Manual Link Resolution

Manually resolve a URI if needed:

```dart
final result = await Dynalinks.handleDeepLink(
  Uri.parse('https://yourproject.dynalinks.app/promo'),
);

if (result.matched) {
  // Handle the resolved link
}
```

## API Reference

### Dynalinks

| Method | Description |
|--------|-------------|
| `configure()` | Initialize the SDK with your API key |
| `checkForDeferredDeepLink()` | Check for deferred deep link (first launch) |
| `handleDeepLink(Uri)` | Manually resolve a deep link URI |
| `getInitialLink()` | Get the link that launched the app (cold start) |
| `onDeepLinkReceived` | Stream of incoming links while app is running |
| `reset()` | Reset SDK state (testing only) |
| `version` | SDK version string |

### DeepLinkResult

| Property | Type | Description |
|----------|------|-------------|
| `matched` | `bool` | Whether a link was matched |
| `confidence` | `Confidence?` | Match confidence (high/medium/low) |
| `matchScore` | `int?` | Match score (0-100) |
| `link` | `LinkData?` | The matched link data |
| `isDeferred` | `bool` | Whether from deferred deep link |

### LinkData

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique link identifier |
| `name` | `String?` | Link name (for display) |
| `path` | `String?` | Link path |
| `shortenedPath` | `String?` | Shortened path |
| `url` | `Uri?` | Original URL the link points to |
| `fullUrl` | `Uri?` | Full Dynalinks URL |
| `deepLinkValue` | `String?` | Value for in-app navigation |
| `iosDeferredDeepLinkingEnabled` | `bool?` | Whether iOS deferred deep linking is enabled |
| `iosFallbackUrl` | `Uri?` | iOS fallback URL (when app not installed) |
| `androidFallbackUrl` | `Uri?` | Android fallback URL (when app not installed) |
| `enableForcedRedirect` | `bool?` | Whether forced redirect is enabled |
| `socialTitle` | `String?` | Social sharing title |
| `socialDescription` | `String?` | Social sharing description |
| `socialImageUrl` | `Uri?` | Social sharing image |
| `clicks` | `int?` | Number of clicks on this link |

### Exceptions

| Exception | Description |
|-----------|-------------|
| `NotConfiguredException` | SDK not configured |
| `InvalidApiKeyException` | Invalid API key |
| `SimulatorException` | Running on simulator/emulator |
| `NetworkException` | Network request failed |
| `InvalidResponseException` | Server returned invalid response |
| `ServerException` | Server returned an error |
| `NoMatchException` | No matching link found |
| `InvalidIntentException` | Invalid intent data (Android) |
| `InstallReferrerUnavailableException` | Install Referrer API unavailable (Android) |
| `InstallReferrerTimeoutException` | Install Referrer connection timed out (Android) |
| `UnknownException` | Unknown error occurred |

## Configuration Options

```dart
await Dynalinks.configure(
  clientAPIKey: 'your-api-key',           // Required
  baseURL: 'https://custom.api.url',      // Optional, custom API URL
  logLevel: DynalinksLogLevel.debug,      // Optional, default: .error
  allowSimulatorOrEmulator: false,        // Optional, default: false
);
```

### Log Levels

- `DynalinksLogLevel.none` - No logging
- `DynalinksLogLevel.error` - Errors only (default)
- `DynalinksLogLevel.warning` - Warnings and errors
- `DynalinksLogLevel.info` - Info, warnings, and errors
- `DynalinksLogLevel.debug` - All logs

## Example App

See the [example](example/) directory for a complete sample app demonstrating all SDK features.

## Support

- [Documentation](https://docs.dynalinks.app)
- [GitHub Issues](https://github.com/dynalinks/dynalinks-flutter-sdk/issues)
- [Email Support](mailto:admins@dynalinks.app)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
