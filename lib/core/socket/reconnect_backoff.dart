import 'dart:math' as math;

/// Exponential backoff schedule used by [SocketReconnectManager] between
/// reconnect attempts.
class ReconnectBackoff {
  final Duration baseDelay;
  final Duration maxDelay;
  final int maxAttempts;

  const ReconnectBackoff({
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(seconds: 30),
    this.maxAttempts = 5,
  });

  /// True once [attempts] has reached the configured ceiling.
  bool isExhausted(int attempts) => attempts >= maxAttempts;

  /// Exponential delay for the given (1-indexed) attempt number.
  Duration delayForAttempt(int attempt) {
    final delaySeconds = math.min(
      baseDelay.inSeconds * math.pow(2, attempt - 1).toInt(),
      maxDelay.inSeconds,
    );
    return Duration(seconds: delaySeconds);
  }
}
