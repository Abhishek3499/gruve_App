import 'package:logger/logger.dart';

/// Renders the already-JSON-encoded message produced by [AppLogger] as-is,
/// one line per line in the payload.
class AppLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    return event.message.toString().split('\n');
  }
}

/// Always logs warning/error; gates debug/info behind [isEnabled] so noisy
/// logs stay out of release builds.
class AppLogFilter extends LogFilter {
  final bool Function() isEnabled;

  AppLogFilter(this.isEnabled);

  @override
  bool shouldLog(LogEvent event) {
    if (event.level.index >= Level.warning.index) {
      return true;
    }

    return isEnabled();
  }
}
