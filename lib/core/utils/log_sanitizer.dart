/// Redacts sensitive values (tokens, passwords, OTPs, credentials, etc.)
/// and strips emoji noise from log payloads before [AppLogger] emits them.
class LogSanitizer {
  LogSanitizer._();

  static final RegExp _sensitiveKeyPattern = RegExp(
    r'(token|password|passwd|otp|secret|authorization|refresh|credential)',
    caseSensitive: false,
  );

  static final RegExp leadingEmojiPattern = RegExp(
    r'^[\u{2100}-\u{214F}'
    r'\u{2190}-\u{21FF}'
    r'\u{2300}-\u{23FF}'
    r'\u{2600}-\u{27BF}'
    r'\u{2B00}-\u{2BFF}'
    r'\u{1F000}-\u{1FFFF}'
    r'\u{FE0F}'
    r'\u{200D}'
    r'\s]+',
    unicode: true,
  );

  static final RegExp _emojiPattern = RegExp(
    r'[\u{2100}-\u{214F}'
    r'\u{2190}-\u{21FF}'
    r'\u{2300}-\u{23FF}'
    r'\u{2600}-\u{27BF}'
    r'\u{2B00}-\u{2BFF}'
    r'\u{1F000}-\u{1FFFF}'
    r'\u{FE0F}'
    r'\u{200D}]',
    unicode: true,
  );

  /// Recursively redacts sensitive map keys and cleans string values.
  static dynamic sanitizeValue(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};

      value.forEach((key, value) {
        final keyString = key.toString();

        result[keyString] = isSensitiveKey(keyString)
            ? '[REDACTED]'
            : sanitizeValue(value);
      });

      return result;
    }

    if (value is Iterable) {
      return value.map(sanitizeValue).toList();
    }

    if (value is String) {
      return cleanText(value);
    }

    return value;
  }

  static bool isSensitiveKey(String key) => _sensitiveKeyPattern.hasMatch(key);

  /// Strips emoji and collapses repeated whitespace.
  static String? cleanText(String? value) {
    if (value == null) {
      return null;
    }

    return value
        .replaceAll(_emojiPattern, '')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
  }
}
