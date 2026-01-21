import 'confidence.dart';
import 'link_data.dart';

/// Result of a deferred deep link check or app link resolution.
///
/// Contains information about whether a link was matched and the
/// associated link data if a match was found.
class DeepLinkResult {
  /// Whether a matching link was found.
  final bool matched;

  /// Confidence level of the match (high, medium, low).
  ///
  /// Only present when [matched] is `true`.
  final Confidence? confidence;

  /// Match score (0-100).
  ///
  /// Higher scores indicate a stronger match.
  /// Only present when [matched] is `true`.
  final int? matchScore;

  /// Link data if matched.
  ///
  /// Contains all information about the matched link including
  /// the [LinkData.deepLinkValue] for navigation.
  final LinkData? link;

  /// Whether this result is from a deferred deep link.
  ///
  /// `true` when the result came from [Dynalinks.checkForDeferredDeepLink].
  /// `false` when the result came from handling an incoming app link.
  final bool isDeferred;

  /// Creates a new [DeepLinkResult].
  const DeepLinkResult({
    required this.matched,
    this.confidence,
    this.matchScore,
    this.link,
    this.isDeferred = false,
  });

  /// Creates a result indicating no match was found.
  factory DeepLinkResult.notMatched({bool isDeferred = false}) {
    return DeepLinkResult(matched: false, isDeferred: isDeferred);
  }

  /// Creates a [DeepLinkResult] from a JSON map.
  factory DeepLinkResult.fromJson(Map<String, dynamic> json) {
    return DeepLinkResult(
      matched: json['matched'] as bool? ?? false,
      confidence: Confidence.fromString(json['confidence'] as String?),
      matchScore: json['match_score'] as int?,
      link: json['link'] != null
          ? LinkData.fromJson(
              Map<String, dynamic>.from(json['link'] as Map))
          : null,
      isDeferred: json['is_deferred'] as bool? ?? false,
    );
  }

  /// Converts this [DeepLinkResult] to a JSON map.
  Map<String, dynamic> toJson() => {
        'matched': matched,
        'confidence': confidence?.name,
        'match_score': matchScore,
        'link': link?.toJson(),
        'is_deferred': isDeferred,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeepLinkResult &&
          runtimeType == other.runtimeType &&
          matched == other.matched &&
          confidence == other.confidence &&
          matchScore == other.matchScore &&
          link == other.link &&
          isDeferred == other.isDeferred;

  @override
  int get hashCode =>
      Object.hash(matched, confidence, matchScore, link, isDeferred);

  @override
  String toString() => 'DeepLinkResult(matched: $matched, '
      'confidence: $confidence, matchScore: $matchScore, '
      'link: $link, isDeferred: $isDeferred)';
}
