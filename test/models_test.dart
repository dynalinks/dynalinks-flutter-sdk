import 'package:flutter_test/flutter_test.dart';
import 'package:dynalinks/dynalinks.dart';

void main() {
  group('Confidence', () {
    test('fromString parses valid values', () {
      expect(Confidence.fromString('high'), equals(Confidence.high));
      expect(Confidence.fromString('medium'), equals(Confidence.medium));
      expect(Confidence.fromString('low'), equals(Confidence.low));
    });

    test('fromString is case insensitive', () {
      expect(Confidence.fromString('HIGH'), equals(Confidence.high));
      expect(Confidence.fromString('Medium'), equals(Confidence.medium));
      expect(Confidence.fromString('LOW'), equals(Confidence.low));
    });

    test('fromString returns null for invalid values', () {
      expect(Confidence.fromString('invalid'), isNull);
      expect(Confidence.fromString(''), isNull);
      expect(Confidence.fromString(null), isNull);
    });
  });

  group('DynalinksLogLevel', () {
    test('has correct values', () {
      expect(DynalinksLogLevel.values, hasLength(5));
      expect(DynalinksLogLevel.none.index, equals(0));
      expect(DynalinksLogLevel.error.index, equals(1));
      expect(DynalinksLogLevel.warning.index, equals(2));
      expect(DynalinksLogLevel.info.index, equals(3));
      expect(DynalinksLogLevel.debug.index, equals(4));
    });
  });

  group('LinkData', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'abc-123',
        'name': 'Test Link',
        'path': '/product',
        'shortened_path': 'xyz',
        'url': 'https://example.com/product?id=123',
        'full_url': 'https://project.dynalinks.app/product',
        'deep_link_value': '/product/123',
        'ios_deferred_deep_linking_enabled': true,
        'android_fallback_url': 'https://play.google.com/store/apps/details?id=com.example',
        'ios_fallback_url': 'https://apps.apple.com/app/id123456',
        'enable_forced_redirect': false,
        'social_title': 'Check out this product',
        'social_description': 'Amazing product description',
        'social_image_url': 'https://example.com/image.png',
        'clicks': 42,
        'referrer': 'utm_source=facebook&utm_campaign=summer',
        'provider_token': '12345678',
        'campaign_token': 'summer_sale',
      };

      final linkData = LinkData.fromJson(json);

      expect(linkData.id, equals('abc-123'));
      expect(linkData.name, equals('Test Link'));
      expect(linkData.path, equals('/product'));
      expect(linkData.shortenedPath, equals('xyz'));
      expect(linkData.url, equals(Uri.parse('https://example.com/product?id=123')));
      expect(linkData.fullUrl, equals(Uri.parse('https://project.dynalinks.app/product')));
      expect(linkData.deepLinkValue, equals('/product/123'));
      expect(linkData.iosDeferredDeepLinkingEnabled, isTrue);
      expect(linkData.androidFallbackUrl?.host, equals('play.google.com'));
      expect(linkData.iosFallbackUrl?.host, equals('apps.apple.com'));
      expect(linkData.enableForcedRedirect, isFalse);
      expect(linkData.socialTitle, equals('Check out this product'));
      expect(linkData.socialDescription, equals('Amazing product description'));
      expect(linkData.socialImageUrl?.path, equals('/image.png'));
      expect(linkData.clicks, equals(42));
      expect(linkData.referrer, equals('utm_source=facebook&utm_campaign=summer'));
      expect(linkData.providerToken, equals('12345678'));
      expect(linkData.campaignToken, equals('summer_sale'));
    });

    test('fromJson handles null optional fields', () {
      final json = {'id': 'minimal-link'};

      final linkData = LinkData.fromJson(json);

      expect(linkData.id, equals('minimal-link'));
      expect(linkData.name, isNull);
      expect(linkData.path, isNull);
      expect(linkData.deepLinkValue, isNull);
      expect(linkData.clicks, isNull);
    });

    test('fromJson handles non-string URL gracefully', () {
      final json = {
        'id': 'link-id',
        'url': 12345, // Non-string value
      };

      final linkData = LinkData.fromJson(json);

      expect(linkData.id, equals('link-id'));
      // Non-string URLs should be null
      expect(linkData.url, isNull);
    });

    test('toJson serializes correctly', () {
      final linkData = LinkData(
        id: 'test-id',
        name: 'Test',
        deepLinkValue: '/test',
        url: Uri.parse('https://example.com'),
      );

      final json = linkData.toJson();

      expect(json['id'], equals('test-id'));
      expect(json['name'], equals('Test'));
      expect(json['deep_link_value'], equals('/test'));
      expect(json['url'], equals('https://example.com'));
    });

    test('equality is based on id', () {
      final link1 = LinkData(id: 'same-id', name: 'Link 1');
      final link2 = LinkData(id: 'same-id', name: 'Link 2');
      final link3 = LinkData(id: 'different-id', name: 'Link 1');

      expect(link1, equals(link2));
      expect(link1, isNot(equals(link3)));
    });

    test('toString returns readable format', () {
      final link = LinkData(id: 'id', path: '/path', deepLinkValue: '/deep');
      expect(link.toString(), contains('id'));
      expect(link.toString(), contains('/path'));
      expect(link.toString(), contains('/deep'));
    });
  });

  group('DeepLinkResult', () {
    test('fromJson parses matched result', () {
      final json = {
        'matched': true,
        'confidence': 'high',
        'match_score': 95,
        'link': {'id': 'link-123', 'path': '/promo'},
        'is_deferred': true,
      };

      final result = DeepLinkResult.fromJson(json);

      expect(result.matched, isTrue);
      expect(result.confidence, equals(Confidence.high));
      expect(result.matchScore, equals(95));
      expect(result.link?.id, equals('link-123'));
      expect(result.isDeferred, isTrue);
    });

    test('fromJson handles not matched result', () {
      final json = {
        'matched': false,
        'is_deferred': false,
      };

      final result = DeepLinkResult.fromJson(json);

      expect(result.matched, isFalse);
      expect(result.confidence, isNull);
      expect(result.matchScore, isNull);
      expect(result.link, isNull);
      expect(result.isDeferred, isFalse);
    });

    test('fromJson defaults matched to false when null', () {
      final json = <String, dynamic>{};

      final result = DeepLinkResult.fromJson(json);

      expect(result.matched, isFalse);
    });

    test('notMatched factory creates correct result', () {
      final result = DeepLinkResult.notMatched(isDeferred: true);

      expect(result.matched, isFalse);
      expect(result.link, isNull);
      expect(result.confidence, isNull);
      expect(result.isDeferred, isTrue);
    });

    test('toJson serializes correctly', () {
      final result = DeepLinkResult(
        matched: true,
        confidence: Confidence.medium,
        matchScore: 75,
        link: LinkData(id: 'test-link'),
        isDeferred: true,
      );

      final json = result.toJson();

      expect(json['matched'], isTrue);
      expect(json['confidence'], equals('medium'));
      expect(json['match_score'], equals(75));
      expect(json['link'], isA<Map>());
      expect(json['is_deferred'], isTrue);
    });

    test('equality works correctly', () {
      final result1 = DeepLinkResult(
        matched: true,
        confidence: Confidence.high,
        matchScore: 90,
        link: LinkData(id: 'link'),
        isDeferred: true,
      );
      final result2 = DeepLinkResult(
        matched: true,
        confidence: Confidence.high,
        matchScore: 90,
        link: LinkData(id: 'link'),
        isDeferred: true,
      );
      final result3 = DeepLinkResult(matched: false);

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });

    test('toString returns readable format', () {
      final result = DeepLinkResult(matched: true, isDeferred: true);
      expect(result.toString(), contains('matched: true'));
      expect(result.toString(), contains('isDeferred: true'));
    });
  });

  group('DynalinksException', () {
    test('fromCode creates correct exception types', () {
      expect(
        DynalinksException.fromCode('NOT_CONFIGURED'),
        isA<NotConfiguredException>(),
      );
      expect(
        DynalinksException.fromCode('INVALID_API_KEY', 'Bad key'),
        isA<InvalidApiKeyException>(),
      );
      expect(
        DynalinksException.fromCode('SIMULATOR'),
        isA<SimulatorException>(),
      );
      expect(
        DynalinksException.fromCode('EMULATOR'),
        isA<SimulatorException>(),
      );
      expect(
        DynalinksException.fromCode('NETWORK_ERROR'),
        isA<NetworkException>(),
      );
      expect(
        DynalinksException.fromCode('INVALID_RESPONSE'),
        isA<InvalidResponseException>(),
      );
      expect(
        DynalinksException.fromCode('SERVER_ERROR', 'Internal error'),
        isA<ServerException>(),
      );
      expect(
        DynalinksException.fromCode('NO_MATCH'),
        isA<NoMatchException>(),
      );
      expect(
        DynalinksException.fromCode('INVALID_INTENT'),
        isA<InvalidIntentException>(),
      );
      expect(
        DynalinksException.fromCode('INSTALL_REFERRER_UNAVAILABLE'),
        isA<InstallReferrerUnavailableException>(),
      );
      expect(
        DynalinksException.fromCode('INSTALL_REFERRER_TIMEOUT'),
        isA<InstallReferrerTimeoutException>(),
      );
      expect(
        DynalinksException.fromCode('UNKNOWN_CODE'),
        isA<UnknownException>(),
      );
    });

    test('exception messages are correct', () {
      expect(
        const NotConfiguredException().message,
        contains('not configured'),
      );
      expect(
        const InvalidApiKeyException('test').message,
        equals('test'),
      );
      expect(
        const SimulatorException().message,
        contains('simulator'),
      );
      expect(
        NetworkException().message,
        contains('Network'),
      );
      expect(
        const InvalidResponseException().message,
        contains('Invalid response'),
      );
      expect(
        const ServerException('Server down').message,
        equals('Server down'),
      );
      expect(
        const NoMatchException().message,
        contains('No matching'),
      );
    });

    test('toString includes exception type and message', () {
      final exception = const NotConfiguredException();
      expect(exception.toString(), contains('NotConfiguredException'));
      expect(exception.toString(), contains('not configured'));
    });
  });
}
