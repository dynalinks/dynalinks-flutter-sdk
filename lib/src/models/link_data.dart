/// Data about a matched deep link.
///
/// Contains all the information about the link that was matched,
/// including routing data, social metadata, and fallback URLs.
class LinkData {
  /// Unique identifier for the link (UUID).
  final String id;

  /// Link name (for display purposes).
  final String? name;

  /// Path component of the link.
  final String? path;

  /// Shortened path for the link.
  final String? shortenedPath;

  /// Original URL the link points to.
  final Uri? url;

  /// Full Dynalinks URL.
  final Uri? fullUrl;

  /// Deep link value for routing in app.
  ///
  /// This is the primary value you should use to determine
  /// where to navigate the user within your app.
  final String? deepLinkValue;

  /// Whether iOS deferred deep linking is enabled for this link.
  final bool? iosDeferredDeepLinkingEnabled;

  /// Android fallback URL (used when app is not installed).
  final Uri? androidFallbackUrl;

  /// iOS fallback URL (used when app is not installed).
  final Uri? iosFallbackUrl;

  /// Whether forced redirect is enabled.
  final bool? enableForcedRedirect;

  /// Social sharing title (used for Open Graph / social previews).
  final String? socialTitle;

  /// Social sharing description (used for Open Graph / social previews).
  final String? socialDescription;

  /// Social sharing image URL (used for Open Graph / social previews).
  final Uri? socialImageUrl;

  /// Number of clicks on this link.
  final int? clicks;

  /// Referrer tracking parameter (e.g., "utm_source=facebook").
  final String? referrer;

  /// Apple Search Ads attribution token (pt parameter).
  final String? providerToken;

  /// Campaign identifier for attribution (ct parameter).
  final String? campaignToken;

  /// Creates a new [LinkData] instance.
  const LinkData({
    required this.id,
    this.name,
    this.path,
    this.shortenedPath,
    this.url,
    this.fullUrl,
    this.deepLinkValue,
    this.iosDeferredDeepLinkingEnabled,
    this.androidFallbackUrl,
    this.iosFallbackUrl,
    this.enableForcedRedirect,
    this.socialTitle,
    this.socialDescription,
    this.socialImageUrl,
    this.clicks,
    this.referrer,
    this.providerToken,
    this.campaignToken,
  });

  /// Creates a [LinkData] from a JSON map.
  factory LinkData.fromJson(Map<String, dynamic> json) {
    return LinkData(
      id: json['id'] as String,
      name: json['name'] as String?,
      path: json['path'] as String?,
      shortenedPath: json['shortened_path'] as String?,
      url: _parseUri(json['url']),
      fullUrl: _parseUri(json['full_url']),
      deepLinkValue: json['deep_link_value'] as String?,
      iosDeferredDeepLinkingEnabled:
          json['ios_deferred_deep_linking_enabled'] as bool?,
      androidFallbackUrl: _parseUri(json['android_fallback_url']),
      iosFallbackUrl: _parseUri(json['ios_fallback_url']),
      enableForcedRedirect: json['enable_forced_redirect'] as bool?,
      socialTitle: json['social_title'] as String?,
      socialDescription: json['social_description'] as String?,
      socialImageUrl: _parseUri(json['social_image_url']),
      clicks: json['clicks'] as int?,
      referrer: json['referrer'] as String?,
      providerToken: json['provider_token'] as String?,
      campaignToken: json['campaign_token'] as String?,
    );
  }

  static Uri? _parseUri(dynamic value) {
    if (value == null) return null;
    if (value is! String) return null;
    return Uri.tryParse(value);
  }

  /// Converts this [LinkData] to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'shortened_path': shortenedPath,
        'url': url?.toString(),
        'full_url': fullUrl?.toString(),
        'deep_link_value': deepLinkValue,
        'ios_deferred_deep_linking_enabled': iosDeferredDeepLinkingEnabled,
        'android_fallback_url': androidFallbackUrl?.toString(),
        'ios_fallback_url': iosFallbackUrl?.toString(),
        'enable_forced_redirect': enableForcedRedirect,
        'social_title': socialTitle,
        'social_description': socialDescription,
        'social_image_url': socialImageUrl?.toString(),
        'clicks': clicks,
        'referrer': referrer,
        'provider_token': providerToken,
        'campaign_token': campaignToken,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkData && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'LinkData(id: $id, path: $path, deepLinkValue: $deepLinkValue)';
}
