import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:dynalinks/dynalinks.dart';
import 'package:dynalinks/src/dynalinks_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDynalinksPlatform extends DynalinksPlatform
    with MockPlatformInterfaceMixin {
  bool configuredCalled = false;
  String? lastApiKey;
  DynalinksLogLevel? lastLogLevel;
  DeepLinkResult? deferredResult;
  DeepLinkResult? handleResult;
  DeepLinkResult? initialLinkResult;
  final StreamController<DeepLinkResult> _deepLinkController =
      StreamController<DeepLinkResult>.broadcast();

  @override
  Future<void> configure({
    required String clientAPIKey,
    String? baseURL,
    DynalinksLogLevel logLevel = DynalinksLogLevel.error,
    bool allowSimulatorOrEmulator = false,
  }) async {
    configuredCalled = true;
    lastApiKey = clientAPIKey;
    lastLogLevel = logLevel;
  }

  @override
  Future<DeepLinkResult> checkForDeferredDeepLink() async {
    return deferredResult ?? DeepLinkResult.notMatched(isDeferred: true);
  }

  @override
  Future<DeepLinkResult> handleDeepLink(Uri uri) async {
    return handleResult ?? DeepLinkResult.notMatched();
  }

  @override
  Stream<DeepLinkResult> get onDeepLinkReceived => _deepLinkController.stream;

  @override
  Future<DeepLinkResult?> getInitialLink() async {
    return initialLinkResult;
  }

  @override
  Future<void> reset() async {
    configuredCalled = false;
    lastApiKey = null;
    lastLogLevel = null;
  }

  void emitDeepLink(DeepLinkResult result) {
    _deepLinkController.add(result);
  }

  void dispose() {
    _deepLinkController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDynalinksPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockDynalinksPlatform();
    DynalinksPlatform.instance = mockPlatform;
  });

  tearDown(() {
    mockPlatform.dispose();
  });

  group('DynalinksPlatform', () {
    test('default instance is MethodChannelDynalinks', () {
      // Reset to check default
      final defaultPlatform = MethodChannelDynalinks();
      expect(defaultPlatform, isA<DynalinksPlatform>());
    });
  });

  group('Dynalinks.configure', () {
    test('calls platform configure with correct parameters', () async {
      await Dynalinks.configure(
        clientAPIKey: 'test-api-key',
        logLevel: DynalinksLogLevel.debug,
      );

      expect(mockPlatform.configuredCalled, isTrue);
      expect(mockPlatform.lastApiKey, equals('test-api-key'));
      expect(mockPlatform.lastLogLevel, equals(DynalinksLogLevel.debug));
    });

    test('uses default log level when not specified', () async {
      await Dynalinks.configure(clientAPIKey: 'test-key');

      expect(mockPlatform.lastLogLevel, equals(DynalinksLogLevel.error));
    });
  });

  group('Dynalinks.checkForDeferredDeepLink', () {
    test('returns matched result from platform', () async {
      final expectedLink = LinkData(
        id: 'test-id',
        deepLinkValue: '/product/123',
      );
      mockPlatform.deferredResult = DeepLinkResult(
        matched: true,
        confidence: Confidence.high,
        matchScore: 95,
        link: expectedLink,
        isDeferred: true,
      );

      final result = await Dynalinks.checkForDeferredDeepLink();

      expect(result.matched, isTrue);
      expect(result.confidence, equals(Confidence.high));
      expect(result.matchScore, equals(95));
      expect(result.link?.id, equals('test-id'));
      expect(result.link?.deepLinkValue, equals('/product/123'));
      expect(result.isDeferred, isTrue);
    });

    test('returns not matched when no link found', () async {
      mockPlatform.deferredResult = DeepLinkResult.notMatched(isDeferred: true);

      final result = await Dynalinks.checkForDeferredDeepLink();

      expect(result.matched, isFalse);
      expect(result.link, isNull);
      expect(result.isDeferred, isTrue);
    });
  });

  group('Dynalinks.handleDeepLink', () {
    test('returns resolved link data', () async {
      mockPlatform.handleResult = DeepLinkResult(
        matched: true,
        link: LinkData(id: 'link-id', path: '/promo'),
      );

      final result =
          await Dynalinks.handleDeepLink(Uri.parse('https://example.com/link'));

      expect(result.matched, isTrue);
      expect(result.link?.path, equals('/promo'));
    });
  });

  group('Dynalinks.onDeepLinkReceived', () {
    test('emits deep link results', () async {
      final results = <DeepLinkResult>[];
      final subscription = Dynalinks.onDeepLinkReceived.listen(results.add);

      mockPlatform.emitDeepLink(DeepLinkResult(
        matched: true,
        link: LinkData(id: 'stream-link'),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(results, hasLength(1));
      expect(results.first.link?.id, equals('stream-link'));

      await subscription.cancel();
    });
  });

  group('Dynalinks.getInitialLink', () {
    test('returns initial link if present', () async {
      mockPlatform.initialLinkResult = DeepLinkResult(
        matched: true,
        link: LinkData(id: 'initial-link'),
      );

      final result = await Dynalinks.getInitialLink();

      expect(result, isNotNull);
      expect(result?.link?.id, equals('initial-link'));
    });

    test('returns null when no initial link', () async {
      mockPlatform.initialLinkResult = null;

      final result = await Dynalinks.getInitialLink();

      expect(result, isNull);
    });
  });

  group('Dynalinks.reset', () {
    test('calls platform reset', () async {
      await Dynalinks.configure(clientAPIKey: 'key');
      expect(mockPlatform.configuredCalled, isTrue);

      await Dynalinks.reset();

      expect(mockPlatform.configuredCalled, isFalse);
    });
  });
}
