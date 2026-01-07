/// Log level for the Dynalinks SDK.
///
/// Controls the verbosity of logs emitted by the SDK.
enum DynalinksLogLevel {
  /// No logging.
  none,

  /// Only errors are logged.
  error,

  /// Warnings and errors are logged.
  warning,

  /// Info, warnings, and errors are logged.
  info,

  /// All logs including debug information.
  debug;
}
