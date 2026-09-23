import 'package:gruve_app/core/utils/app_logger.dart';

/// Safe parsing helpers for type-safe API response handling
class SafeParsingHelpers {
  static const String _tag = 'SafeParsing';

  /// Safely parse a dynamic value to `Map<String, dynamic>`
  /// Returns empty map if parsing fails
  static Map<String, dynamic> safeMapParse(dynamic data, {String? context}) {
    final ctx = context ?? 'Unknown';
    if (data == null) {
      AppLogger.debug(
        _tag,
        'map_parse',
        data: {'context': ctx, 'result': 'null'},
      );
      return {};
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } catch (e) {
        AppLogger.warning(
          _tag,
          'map_parse_failed',
          data: {'context': ctx, 'error': e.toString()},
        );
        return {};
      }
    }

    AppLogger.warning(
      _tag,
      'map_parse',
      data: {
        'context': ctx,
        'actualType': data.runtimeType.toString(),
        'expected': 'Map',
      },
    );
    return {};
  }

  /// Safely parse a dynamic value to `List<dynamic>`
  /// Returns empty list if parsing fails
  static List<dynamic> safeListParse(dynamic data, {String? context}) {
    final ctx = context ?? 'Unknown';
    if (data == null) {
      AppLogger.debug(
        _tag,
        'list_parse',
        data: {'context': ctx, 'result': 'null'},
      );
      return [];
    }

    if (data is List) {
      return data;
    }

    AppLogger.warning(
      _tag,
      'list_parse',
      data: {
        'context': ctx,
        'actualType': data.runtimeType.toString(),
        'expected': 'List',
      },
    );
    return [];
  }

  /// Safely extract a map from a list by index
  static Map<String, dynamic> safeMapFromList(
    dynamic data,
    int index, {
    String? context,
  }) {
    final ctx = context ?? 'Unknown';
    final list = safeListParse(data, context: context);
    if (index >= 0 && index < list.length) {
      return safeMapParse(list[index], context: '$ctx[$index]');
    }
    AppLogger.warning(
      _tag,
      'list_index_out_of_bounds',
      data: {'context': ctx, 'index': index, 'length': list.length},
    );
    return {};
  }

  /// Safely extract a nested value from a map
  static T? safeValueExtract<T>(
    Map<String, dynamic> map,
    List<String> keys, {
    T? defaultValue,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) {
        if (value is T) return value;
        if (T == String && value != null) return value.toString() as T;
        if (T == int && value is num) return value.toInt() as T;
        if (T == double && value is num) return value.toDouble() as T;
        if (T == bool && value is bool) return value as T;
      }
    }
    return defaultValue;
  }

  /// Safely extract a string value from a map
  static String safeString(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    return safeValueExtract<String>(map, keys, defaultValue: fallback) ??
        fallback;
  }

  /// Safely extract a nullable string value from a map
  static String? safeNullableString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) {
        final stringValue = value.toString().trim();
        if (stringValue.isNotEmpty && stringValue.toLowerCase() != 'null') {
          return stringValue;
        }
      }
    }
    return null;
  }

  /// Safely extract an integer value from a map
  static int safeInt(
    Map<String, dynamic> map,
    List<String> keys, {
    int fallback = 0,
  }) {
    return safeValueExtract<int>(map, keys, defaultValue: fallback) ?? fallback;
  }

  /// Safely extract a boolean value from a map
  static bool safeBool(
    Map<String, dynamic> map,
    List<String> keys, {
    bool fallback = false,
  }) {
    return safeValueExtract<bool>(map, keys, defaultValue: fallback) ??
        fallback;
  }

  /// Log detailed information about response data for debugging.
  /// Logs shape (keys/types/lengths) only — never raw field values, since
  /// this is called on arbitrary API responses that may contain PII.
  static void logResponseInfo(dynamic data, String context) {
    if (data == null) {
      AppLogger.debug(
        _tag,
        'response_shape',
        data: {'context': context, 'type': 'null'},
      );
      return;
    }

    if (data is Map) {
      AppLogger.debug(
        _tag,
        'response_shape',
        data: {
          'context': context,
          'type': 'Map',
          'keys': data.keys.map((k) => k.toString()).toList(),
          'length': data.length,
        },
      );
    } else if (data is List) {
      AppLogger.debug(
        _tag,
        'response_shape',
        data: {
          'context': context,
          'type': 'List',
          'length': data.length,
          if (data.isNotEmpty)
            'firstItemType': data.first.runtimeType.toString(),
          if (data.isNotEmpty && data.first is Map)
            'firstItemKeys': (data.first as Map).keys
                .map((k) => k.toString())
                .toList(),
        },
      );
    } else {
      AppLogger.debug(
        _tag,
        'response_shape',
        data: {'context': context, 'type': data.runtimeType.toString()},
      );
    }
  }

  /// Validate and clean map keys to ensure they are strings
  static Map<String, dynamic> validateAndCleanMap(
    dynamic data, {
    String? context,
  }) {
    final map = safeMapParse(data, context: context);
    final cleaned = <String, dynamic>{};

    for (final entry in map.entries) {
      final key = entry.key.toString();
      cleaned[key] = entry.value;
    }

    return cleaned;
  }
}
