import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dynalinks_platform_interface.dart';
import 'models/deep_link_result.dart';
import 'models/dynalinks_exception.dart';
import 'models/dynalinks_log_level.dart';

/// Method channel implementation of [DynalinksPlatform].
class MethodChannelDynalinks extends DynalinksPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.dynalinks.sdk/dynalinks');

  /// The event channel for receiving deep link events.
  @visibleForTesting
  final eventChannel = const EventChannel('com.dynalinks.sdk/deep_links');

  /// Cached stream of deep link events.
  Stream<DeepLinkResult>? _deepLinkStream;

  @override
  Future<void> configure({
    required String clientAPIKey,
    String? baseURL,
    DynalinksLogLevel logLevel = DynalinksLogLevel.error,
    bool allowSimulatorOrEmulator = false,
  }) async {
    try {
      await methodChannel.invokeMethod<void>('configure', {
        'clientAPIKey': clientAPIKey,
        'baseURL': baseURL,
        'logLevel': logLevel.name,
        'allowSimulatorOrEmulator': allowSimulatorOrEmulator,
      });
    } on PlatformException catch (e) {
      throw DynalinksException.fromCode(e.code, e.message);
    }
  }

  @override
  Future<DeepLinkResult> checkForDeferredDeepLink() async {
    try {
      final result = await methodChannel
          .invokeMapMethod<String, dynamic>('checkForDeferredDeepLink');
      if (result == null) {
        return DeepLinkResult.notMatched(isDeferred: true);
      }
      return DeepLinkResult.fromJson(result);
    } on PlatformException catch (e) {
      throw DynalinksException.fromCode(e.code, e.message);
    }
  }

  @override
  Future<DeepLinkResult> handleDeepLink(Uri uri) async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'handleDeepLink',
        {'uri': uri.toString()},
      );
      if (result == null) {
        return DeepLinkResult.notMatched();
      }
      return DeepLinkResult.fromJson(result);
    } on PlatformException catch (e) {
      throw DynalinksException.fromCode(e.code, e.message);
    }
  }

  @override
  Stream<DeepLinkResult> get onDeepLinkReceived {
    _deepLinkStream ??= eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return DeepLinkResult.fromJson(Map<String, dynamic>.from(event));
      }
      return DeepLinkResult.notMatched();
    });
    return _deepLinkStream!;
  }

  @override
  Future<DeepLinkResult?> getInitialLink() async {
    try {
      final result = await methodChannel
          .invokeMapMethod<String, dynamic>('getInitialLink');
      if (result == null) return null;
      return DeepLinkResult.fromJson(result);
    } on PlatformException catch (e) {
      throw DynalinksException.fromCode(e.code, e.message);
    }
  }

  @override
  Future<void> reset() async {
    await methodChannel.invokeMethod<void>('reset');
  }
}
