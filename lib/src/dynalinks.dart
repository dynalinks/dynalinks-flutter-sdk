import 'package:flutter/foundation.dart';

import 'dynalinks_platform_interface.dart';
import 'models/deep_link_result.dart';
import 'models/dynalinks_log_level.dart';

/// Main entry point for the Dynalinks SDK.
///
/// Configure the SDK early in your app's lifecycle and use it to check
/// for deferred deep links and handle incoming Universal/App Links.
///
/// ## Usage
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   await Dynalinks.configure(
///     clientAPIKey: 'your-api-key',
///     logLevel: DynalinksLogLevel.debug,
///   );
///
///   runApp(const MyApp());
/// }
/// ```
class Dynalinks {
  Dynalinks._();

  static DynalinksPlatform get _platform => DynalinksPlatform.instance;

  /// Current SDK version.
  static const String version = '1.0.4';

  /// Configure the Dynalinks SDK.
  ///
  /// Call this method as early as possible in your app's lifecycle,
  /// typically in `main()` before `runApp()`.
  ///
  /// [clientAPIKey] - Your project's client API key from the Dynalinks console.
  /// [baseURL] - Optional API base URL (defaults to production).
  /// [logLevel] - Logging verbosity (defaults to [DynalinksLogLevel.error]).
  /// [allowSimulatorOrEmulator] - Allow checks on simulator/emulator (defaults to false).
  ///
  /// Throws [DynalinksException] if the API key is invalid.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await Dynalinks.configure(
  ///   clientAPIKey: 'your-client-api-key',
  ///   logLevel: DynalinksLogLevel.debug,
  ///   allowSimulatorOrEmulator: true, // For testing
  /// );
  /// ```
  static Future<void> configure({
    required String clientAPIKey,
    String? baseURL,
    DynalinksLogLevel logLevel = DynalinksLogLevel.error,
    bool allowSimulatorOrEmulator = false,
  }) {
    return _platform.configure(
      clientAPIKey: clientAPIKey,
      baseURL: baseURL,
      logLevel: logLevel,
      allowSimulatorOrEmulator: allowSimulatorOrEmulator,
    );
  }

  /// Check for a deferred deep link.
  ///
  /// This method should be called once after the first app launch.
  /// It will check if the user came from a Dynalinks link before installing.
  ///
  /// The SDK automatically prevents duplicate checks - subsequent calls
  /// will return the cached result.
  ///
  /// Returns a [DeepLinkResult] containing the matched link data.
  ///
  /// Throws [DynalinksException] on errors:
  /// - [NotConfiguredException] if SDK is not configured
  /// - [SimulatorException] if running on simulator/emulator
  /// - [NetworkException] on network failures
  /// - [ServerException] on server errors
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   final result = await Dynalinks.checkForDeferredDeepLink();
  ///   if (result.matched && result.link?.deepLinkValue != null) {
  ///     // Navigate to the deep link destination
  ///     navigateTo(result.link!.deepLinkValue!);
  ///   }
  /// } on SimulatorException {
  ///   // Running on simulator, deferred deep linking not available
  /// } on DynalinksException catch (e) {
  ///   print('Error checking for deferred deep link: $e');
  /// }
  /// ```
  static Future<DeepLinkResult> checkForDeferredDeepLink() {
    return _platform.checkForDeferredDeepLink();
  }

  /// Handle a Universal Link (iOS) or App Link (Android) that opened the app.
  ///
  /// Call this when your app receives an incoming deep link URL.
  /// This is typically used when you need to manually handle links
  /// instead of using [onDeepLinkReceived].
  ///
  /// [uri] - The URI that opened the app.
  ///
  /// Returns a [DeepLinkResult] with the resolved link data.
  ///
  /// Throws [DynalinksException] if not configured or the request fails.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final result = await Dynalinks.handleDeepLink(incomingUri);
  /// if (result.matched) {
  ///   navigateTo(result.link?.deepLinkValue);
  /// }
  /// ```
  static Future<DeepLinkResult> handleDeepLink(Uri uri) {
    return _platform.handleDeepLink(uri);
  }

  /// Stream of incoming deep links received while the app is running.
  ///
  /// Listen to this stream to handle links that arrive while your app
  /// is already open (warm start scenario).
  ///
  /// For cold start links (app launched from a link), use [getInitialLink].
  ///
  /// ## Example
  ///
  /// ```dart
  /// class _MyAppState extends State<MyApp> {
  ///   StreamSubscription<DeepLinkResult>? _linkSubscription;
  ///
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     _linkSubscription = Dynalinks.onDeepLinkReceived.listen((result) {
  ///       if (result.matched) {
  ///         navigateTo(result.link?.deepLinkValue);
  ///       }
  ///     });
  ///   }
  ///
  ///   @override
  ///   void dispose() {
  ///     _linkSubscription?.cancel();
  ///     super.dispose();
  ///   }
  /// }
  /// ```
  static Stream<DeepLinkResult> get onDeepLinkReceived {
    return _platform.onDeepLinkReceived;
  }

  /// Get the initial deep link that launched the app (cold start).
  ///
  /// Returns `null` if the app was not launched from a deep link.
  /// This method can only return a value once per app launch -
  /// subsequent calls will return `null`.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   _checkInitialLink();
  /// }
  ///
  /// Future<void> _checkInitialLink() async {
  ///   final initialLink = await Dynalinks.getInitialLink();
  ///   if (initialLink != null && initialLink.matched) {
  ///     navigateTo(initialLink.link?.deepLinkValue);
  ///   }
  /// }
  /// ```
  static Future<DeepLinkResult?> getInitialLink() {
    return _platform.getInitialLink();
  }

  /// Reset the SDK state (for testing only).
  ///
  /// Clears cached results and allows [checkForDeferredDeepLink]
  /// to be called again. This should only be used in tests.
  @visibleForTesting
  static Future<void> reset() {
    return _platform.reset();
  }
}
