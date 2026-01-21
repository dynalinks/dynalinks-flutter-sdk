import 'package:dynalinks/src/models/deep_link_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Platform Channel Type Safety', () {
    test('FIXED CODE: Handles nested Map<Object?, Object?> from Android', () {
      // This simulates what Android's platform channel actually returns
      // The top level map is Map<String, dynamic> but nested maps are Map<Object?, Object?>
      final Map<String, dynamic> platformChannelResponse = {
        'matched': true,
        'confidence': 'high',
        'match_score': 95,
        'is_deferred': true,
        // This nested map would cause TypeError without the fix
        'link': <Object?, Object?>{
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'name': 'Test Link',
          'path': '/test',
          'deep_link_value': 'myapp://test',
        },
      };

      // With Map<String, dynamic>.from() fix, this works
      final result = DeepLinkResult.fromJson(platformChannelResponse);

      expect(result.matched, true);
      expect(result.link?.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(result.link?.deepLinkValue, 'myapp://test');
    });

    test('Works with properly typed nested maps too', () {
      // Regular Dart maps (like from unit tests) still work
      final Map<String, dynamic> dartMap = {
        'matched': true,
        'confidence': 'high',
        'match_score': 95,
        'is_deferred': true,
        'link': <String, dynamic>{
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'name': 'Test Link',
          'path': '/test',
          'deep_link_value': 'myapp://test',
        },
      };

      final result = DeepLinkResult.fromJson(dartMap);

      expect(result.matched, true);
      expect(result.link?.id, '123e4567-e89b-12d3-a456-426614174000');
    });
  });
}
