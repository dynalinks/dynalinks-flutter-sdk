/// Confidence level of a deep link match.
enum Confidence {
  /// High confidence match (exact match on device ID or other strong signals).
  high,

  /// Medium confidence match (multiple fingerprint signals matched).
  medium,

  /// Low confidence match (few fingerprint signals matched).
  low;

  /// Create a [Confidence] from a string value.
  ///
  /// Returns `null` if the value is `null` or not a valid confidence level.
  static Confidence? fromString(String? value) {
    if (value == null) return null;
    return switch (value.toLowerCase()) {
      'high' => Confidence.high,
      'medium' => Confidence.medium,
      'low' => Confidence.low,
      _ => null,
    };
  }
}
