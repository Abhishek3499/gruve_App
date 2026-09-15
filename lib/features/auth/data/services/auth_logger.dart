import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Pretty-printed debug logger for the auth feature.
/// Silent outside debug mode — see production rules in features/auth/README.md
/// (never log passwords, OTPs, tokens, headers, or full response bodies).
final Logger authLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 100,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
  filter: _DebugOnlyFilter(),
);

class _DebugOnlyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => kDebugMode;
}
