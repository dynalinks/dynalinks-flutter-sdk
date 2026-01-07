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

1. Add the `DynalinksSDK` CocoaPod (automatically included via plugin)

2. Configure your Associated Domains in Xcode:
   - Open your iOS project in Xcode
   - Select your target > Signing & Capabilities
   - Add the "Associated Domains" capability
   - Add your Dynalinks domain: `applinks:yourproject.dynalinks.app`

3. Add the `apple-app-site-association` file to your Dynalinks project dashboard

### Android Setup

1. Add JitPack repository to your project's `settings.gradle` or `build.gradle`:

```kotlin
// settings.gradle.kts
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
```

Or in Groovy (`settings.gradle`):

```groovy
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

2. Add intent filters to your `AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTask">

    <!-- App Links -->
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

3. Configure Digital Asset Links in your Dynalinks project dashboard

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
| `deepLinkValue` | `String?` | Value for in-app navigation |
| `path` | `String?` | Link path |
| `fullUrl` | `Uri?` | Full Dynalinks URL |
| `socialTitle` | `String?` | Social sharing title |
| `socialDescription` | `String?` | Social sharing description |
| `socialImageUrl` | `Uri?` | Social sharing image |

### Exceptions

| Exception | Description |
|-----------|-------------|
| `NotConfiguredException` | SDK not configured |
| `InvalidApiKeyException` | Invalid API key |
| `SimulatorException` | Running on simulator/emulator |
| `NetworkException` | Network request failed |
| `ServerException` | Server returned an error |
| `NoMatchException` | No matching link found |

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

- [Documentation](https://dynalinks.app/docs)
- [GitHub Issues](https://github.com/dynalinks/dynalinks-flutter-sdk/issues)
- [Email Support](mailto:support@dynalinks.app)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
