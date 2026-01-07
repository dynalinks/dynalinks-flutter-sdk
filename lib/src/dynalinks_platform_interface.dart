import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'dynalinks_method_channel.dart';
import 'models/deep_link_result.dart';
import 'models/dynalinks_log_level.dart';

/// Platform interface for the Dynalinks SDK.
///
/// Platform-specific implementations should extend this class.
abstract class DynalinksPlatform extends PlatformInterface {
  /// Constructs a [DynalinksPlatform].
  DynalinksPlatform() : super(token: _token);

  static final Object _token = Object();

  static DynalinksPlatform _instance = MethodChannelDynalinks();

  /// The default instance of [DynalinksPlatform] to use.
  ///
  /// Defaults to [MethodChannelDynalinks].
  static DynalinksPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DynalinksPlatform] when
  /// they register themselves.
  static set instance(DynalinksPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Configure the Dynalinks SDK.
  ///
  /// Must be called before any other SDK methods.
  Future<void> configure({
    required String clientAPIKey,
    String? baseURL,
    DynalinksLogLevel logLevel = DynalinksLogLevel.error,
    bool allowSimulatorOrEmulator = false,
  }) {
    throw UnimplementedError('configure() has not been implemented.');
  }

  /// Check for a deferred deep link.
  ///
  /// Returns a [DeepLinkResult] with the matched link data.
  Future<DeepLinkResult> checkForDeferredDeepLink() {
    throw UnimplementedError(
        'checkForDeferredDeepLink() has not been implemented.');
  }

  /// Handle a Universal Link (iOS) or App Link (Android).
  ///
  /// [uri] - The URI that opened the app.
  /// Returns a [DeepLinkResult] with the resolved link data.
  Future<DeepLinkResult> handleDeepLink(Uri uri) {
    throw UnimplementedError('handleDeepLink() has not been implemented.');
  }

  /// Stream of incoming deep links received while the app is running.
  ///
  /// Listen to this stream to handle links that arrive while your app
  /// is already open (warm start scenario).
  Stream<DeepLinkResult> get onDeepLinkReceived {
    throw UnimplementedError(
        'onDeepLinkReceived has not been implemented.');
  }

  /// Get the initial deep link that launched the app (cold start).
  ///
  /// Returns `null` if the app was not launched from a deep link.
  /// This method can only return a value once per app launch.
  Future<DeepLinkResult?> getInitialLink() {
    throw UnimplementedError('getInitialLink() has not been implemented.');
  }

  /// Reset the SDK state (for testing only).
  ///
  /// Clears cached results and allows [checkForDeferredDeepLink]
  /// to be called again.
  Future<void> reset() {
    throw UnimplementedError('reset() has not been implemented.');
  }
}
