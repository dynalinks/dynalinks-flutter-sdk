/// Base exception for all Dynalinks SDK errors.
///
/// All exceptions thrown by the Dynalinks SDK are subclasses of this class.
sealed class DynalinksException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Creates a new [DynalinksException] with the given [message].
  const DynalinksException(this.message);

  @override
  String toString() => '$runtimeType: $message';

  /// Creates a [DynalinksException] from an error code returned by the native platform.
  ///
  /// This is used internally by the SDK to convert platform errors
  /// to typed Dart exceptions.
  factory DynalinksException.fromCode(String code, [String? message]) {
    return switch (code) {
      'NOT_CONFIGURED' => const NotConfiguredException(),
      'INVALID_API_KEY' => InvalidApiKeyException(message ?? 'Invalid API key'),
      'SIMULATOR' || 'EMULATOR' => const SimulatorException(),
      'NETWORK_ERROR' => NetworkException(message),
      'INVALID_RESPONSE' => const InvalidResponseException(),
      'SERVER_ERROR' => ServerException(message ?? 'Server error'),
      'NO_MATCH' => const NoMatchException(),
      'INVALID_INTENT' => const InvalidIntentException(),
      'INSTALL_REFERRER_UNAVAILABLE' =>
        const InstallReferrerUnavailableException(),
      'INSTALL_REFERRER_TIMEOUT' => const InstallReferrerTimeoutException(),
      _ => UnknownException(message ?? 'Unknown error: $code'),
    };
  }
}

/// Thrown when the SDK has not been configured.
///
/// Call [Dynalinks.configure] before using any other SDK methods.
class NotConfiguredException extends DynalinksException {
  /// Creates a new [NotConfiguredException].
  const NotConfiguredException()
      : super('Dynalinks SDK not configured. Call Dynalinks.configure() first.');
}

/// Thrown when the API key format is invalid.
///
/// Ensure you are using a valid client API key from the Dynalinks console.
class InvalidApiKeyException extends DynalinksException {
  /// Creates a new [InvalidApiKeyException] with the given [message].
  const InvalidApiKeyException(super.message);
}

/// Thrown when running on simulator/emulator and that is not allowed.
///
/// Deferred deep linking is not available on simulators/emulators by default.
/// Set `allowSimulatorOrEmulator: true` in [Dynalinks.configure] to override.
class SimulatorException extends DynalinksException {
  /// Creates a new [SimulatorException].
  const SimulatorException()
      : super('Deferred deep linking not available on simulator/emulator.');
}

/// Thrown when a network request fails.
///
/// This can happen due to connectivity issues or server unreachability.
class NetworkException extends DynalinksException {
  /// Creates a new [NetworkException] with an optional [message].
  NetworkException([String? message]) : super(message ?? 'Network request failed.');
}

/// Thrown when the server returns an invalid response.
///
/// This typically indicates a server-side issue or API version mismatch.
class InvalidResponseException extends DynalinksException {
  /// Creates a new [InvalidResponseException].
  const InvalidResponseException() : super('Invalid response from server.');
}

/// Thrown when the server returns an error.
///
/// Check the [message] for details about the server error.
class ServerException extends DynalinksException {
  /// Creates a new [ServerException] with the given [message].
  const ServerException(super.message);
}

/// Thrown when no matching deep link was found.
///
/// This is not necessarily an error - it simply means the user
/// did not come from a Dynalinks link.
class NoMatchException extends DynalinksException {
  /// Creates a new [NoMatchException].
  const NoMatchException() : super('No matching deferred deep link found.');
}

/// Thrown when the intent does not contain valid deep link data.
///
/// This is Android-specific and occurs when [Dynalinks.handleDeepLink]
/// is called with an intent that doesn't contain a valid URI.
class InvalidIntentException extends DynalinksException {
  /// Creates a new [InvalidIntentException].
  const InvalidIntentException()
      : super('Intent does not contain valid deep link data.');
}

/// Thrown when the Google Play Install Referrer API is unavailable.
///
/// This is Android-specific and can occur on devices without
/// Google Play Services or when the API is not supported.
class InstallReferrerUnavailableException extends DynalinksException {
  /// Creates a new [InstallReferrerUnavailableException].
  const InstallReferrerUnavailableException()
      : super('Install Referrer API is not available.');
}

/// Thrown when the Install Referrer connection times out.
///
/// This is Android-specific and can occur when the Google Play
/// Store takes too long to respond.
class InstallReferrerTimeoutException extends DynalinksException {
  /// Creates a new [InstallReferrerTimeoutException].
  const InstallReferrerTimeoutException()
      : super('Install Referrer connection timed out.');
}

/// Thrown when an unknown error occurs.
///
/// This is a catch-all for errors not covered by other exception types.
class UnknownException extends DynalinksException {
  /// Creates a new [UnknownException] with the given [message].
  const UnknownException(super.message);
}
