import 'package:flutter/foundation.dart';

/// Safe parsing helpers for type-safe API response handling
class SafeParsingHelpers {
  /// Safely parse a dynamic value to Map<String, dynamic>
  /// Returns empty map if parsing fails
  static Map<String, dynamic> safeMapParse(dynamic data, {String? context}) {
    if (data == null) {
      debugPrint('� [SafeParsing] ${context ?? 'Unknown'}: data is null, returning empty map');
      return {};
    }
    
    if (data is Map<String, dynamic>) {
      debugPrint('✅ [SafeParsing] ${context ?? 'Unknown'}: data is already Map<String, dynamic>');
      return data;
    }
    
    if (data is Map) {
      try {
        final result = Map<String, dynamic>.from(data);
        debugPrint('🔄 [SafeParsing] ${context ?? 'Unknown'}: converted Map<dynamic, dynamic> to Map<String, dynamic>');
        return result;
      } catch (e) {
        debugPrint('💥 [SafeParsing] ${context ?? 'Unknown'}: failed to convert map: $e');
        return {};
      }
    }
    
    debugPrint('⚠️ [SafeParsing] ${context ?? 'Unknown'}: data is ${data.runtimeType}, expected Map, returning empty map');
    return {};
  }

  /// Safely parse a dynamic value to List<dynamic>
  /// Returns empty list if parsing fails
  static List<dynamic> safeListParse(dynamic data, {String? context}) {
    if (data == null) {
      debugPrint('� [SafeParsing] ${context ?? 'Unknown'}: data is null, returning empty list');
      return [];
    }
    
    if (data is List) {
      debugPrint('📋 [SafeParsing] ${context ?? 'Unknown'}: data is already List with ${data.length} items');
      return data;
    }
    
    debugPrint('⚠️ [SafeParsing] ${context ?? 'Unknown'}: data is ${data.runtimeType}, expected List, returning empty list');
    return [];
  }

  /// Safely extract a map from a list by index
  static Map<String, dynamic> safeMapFromList(dynamic data, int index, {String? context}) {
    final list = safeListParse(data, context: context);
    if (index >= 0 && index < list.length) {
      debugPrint('📍 [SafeParsing] ${context ?? 'Unknown'}: extracting item at index $index from list of ${list.length}');
      return safeMapParse(list[index], context: '${context ?? 'Unknown'}[$index]');
    }
    debugPrint('❌ [SafeParsing] ${context ?? 'Unknown'}: index $index out of bounds for list of length ${list.length}');
    return {};
  }

  /// Safely extract a nested value from a map
  static T? safeValueExtract<T>(Map<String, dynamic> map, List<String> keys, {T? defaultValue}) {
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
  static String safeString(Map<String, dynamic> map, List<String> keys, {String fallback = ''}) {
    return safeValueExtract<String>(map, keys, defaultValue: fallback) ?? fallback;
  }

  /// Safely extract a nullable string value from a map
  static String? safeNullableString(Map<String, dynamic> map, List<String> keys) {
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
  static int safeInt(Map<String, dynamic> map, List<String> keys, {int fallback = 0}) {
    return safeValueExtract<int>(map, keys, defaultValue: fallback) ?? fallback;
  }

  /// Safely extract a boolean value from a map
  static bool safeBool(Map<String, dynamic> map, List<String> keys, {bool fallback = false}) {
    return safeValueExtract<bool>(map, keys, defaultValue: fallback) ?? fallback;
  }

  /// Log detailed information about response data for debugging
  static void logResponseInfo(dynamic data, String context) {
    debugPrint('📊 [ResponseDebug] 🚀 $context - RuntimeType: ${data.runtimeType}');
    
    if (data == null) {
      debugPrint('📊 [ResponseDebug] 🚫 $context - Data: null');
      return;
    }
    
    if (data is Map) {
      debugPrint('📊 [ResponseDebug] 🗺️ $context - Map keys: ${(data as Map).keys.toList()}');
      debugPrint('📊 [ResponseDebug] 📏 $context - Map length: ${(data as Map).length}');
      
      // Log first few key-value pairs for inspection
      final entries = (data as Map).entries.take(3).toList();
      for (final entry in entries) {
        debugPrint('📊 [ResponseDebug] 🔑 $context - Sample: ${entry.key}: ${entry.value} (${entry.value.runtimeType})');
      }
    } else if (data is List) {
      debugPrint('📊 [ResponseDebug] 📋 $context - List length: ${data.length}');
      if (data.isNotEmpty) {
        debugPrint('📊 [ResponseDebug] 📦 $context - First item type: ${data.first.runtimeType}');
        if (data.first is Map) {
          debugPrint('📊 [ResponseDebug] 🗺️ $context - First item keys: ${(data.first as Map).keys.toList()}');
        }
      }
    } else {
      debugPrint('📊 [ResponseDebug] 💎 $context - Value: $data');
    }
  }

  /// Validate and clean map keys to ensure they are strings
  static Map<String, dynamic> validateAndCleanMap(dynamic data, {String? context}) {
    debugPrint('🧹 [SafeParsing] 🧽 ${context ?? 'Unknown'}: starting map validation and cleaning');
    final map = safeMapParse(data, context: context);
    final cleaned = <String, dynamic>{};
    
    for (final entry in map.entries) {
      final key = entry.key.toString();
      cleaned[key] = entry.value;
    }
    
    debugPrint('✨ [SafeParsing] 🌟 ${context ?? 'Unknown'}: cleaned map has ${cleaned.length} string keys');
    return cleaned;
  }
}
