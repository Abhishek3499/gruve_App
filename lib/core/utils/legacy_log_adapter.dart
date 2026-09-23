import 'package:gruve_app/core/utils/log_sanitizer.dart';

/// Parses legacy shorthand log calls (e.g. `AppLogger.d('[Tag] message')` or
/// `AppLogger.d('🔐 message')`) into a structured (tag, message) pair, so
/// call sites that haven't migrated to the structured `AppLogger.debug(...)`
/// API still produce consistent structured output.
class LegacyLogAdapter {
  LegacyLogAdapter._();

  static final RegExp _legacyTagPattern = RegExp(r'^\s*\[([^\]]+)\]\s*');

  static ({String? tag, String message}) parse(String message, String? tag) {
    if (tag != null && tag.trim().isNotEmpty) {
      return (tag: tag.trim(), message: message.trim());
    }

    final cleanedMessage = message.replaceFirst(
      LogSanitizer.leadingEmojiPattern,
      '',
    );

    final match = _legacyTagPattern.firstMatch(cleanedMessage);

    if (match == null) {
      return (tag: null, message: message.trim());
    }

    final extractedTag = match.group(1)?.trim();

    return (
      tag: extractedTag?.isEmpty == true ? null : extractedTag,
      message: cleanedMessage.substring(match.end).trim(),
    );
  }
}
