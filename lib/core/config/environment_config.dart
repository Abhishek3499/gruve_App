import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration management.
class EnvironmentConfig {
  static late Environment _environment;
  static late String _baseUrl;
  static late String _wsUrl;
  static late bool _enableLogging;
  static late bool _enableDebugTools;
  static late bool _enableCrashReporting;
  static late int _apiTimeout;
  static late int _wsTimeout;

  static Future<void> initialize() async {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
    }

    const environment = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'development',
    );
    _environment = _parseEnvironment(environment);
    _loadConfiguration();

    if (kDebugMode) {
      debugPrint('[Environment] Initialized: ${_environment.name}');
    }
  }

  static Environment _parseEnvironment(String env) {
    switch (env.toLowerCase()) {
      case 'production':
      case 'prod':
        return Environment.production;
      case 'staging':
      case 'stage':
        return Environment.staging;
      case 'development':
      case 'dev':
      default:
        return Environment.development;
    }
  }

  static void _loadConfiguration() {
    switch (_environment) {
      case Environment.production:
        _baseUrl = _envValue('PROD_BASE_URL', fallbackKey: 'BASE_URL');
        _wsUrl = _envValue('PROD_WS_URL', fallbackKey: 'WS_URL');
        _enableLogging = false;
        _enableDebugTools = false;
        _enableCrashReporting = true;
        _apiTimeout = 30;
        _wsTimeout = 15;
        break;
      case Environment.staging:
        _baseUrl = _envValue('STAGING_BASE_URL', fallbackKey: 'BASE_URL');
        _wsUrl = _envValue('STAGING_WS_URL', fallbackKey: 'WS_URL');
        _enableLogging = true;
        _enableDebugTools = false;
        _enableCrashReporting = true;
        _apiTimeout = 25;
        _wsTimeout = 12;
        break;
      case Environment.development:
        _baseUrl = _envValue('DEV_BASE_URL', fallbackKey: 'BASE_URL');
        _wsUrl = _envValue('DEV_WS_URL', fallbackKey: 'WS_URL');
        _enableLogging = true;
        _enableDebugTools = true;
        _enableCrashReporting = false;
        _apiTimeout = 20;
        _wsTimeout = 10;
        break;
    }
  }

  static String _envValue(String key, {String? fallbackKey}) {
    final value = dotenv.env[key]?.trim();
    if (value != null && value.isNotEmpty) return value;

    if (fallbackKey != null) {
      final fallback = dotenv.env[fallbackKey]?.trim();
      if (fallback != null && fallback.isNotEmpty) return fallback;
    }

    throw StateError(
      '[Environment] Missing $key${fallbackKey == null ? '' : ' or $fallbackKey'} in .env',
    );
  }

  static Environment get environment => _environment;
  static String get baseUrl => _baseUrl;
  static String get wsUrl => _wsUrl;
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  static bool get enableLogging => _enableLogging;
  static bool get enableDebugTools => _enableDebugTools;
  static bool get enableCrashReporting => _enableCrashReporting;
  static int get apiTimeout => _apiTimeout;
  static int get wsTimeout => _wsTimeout;

  static Map<String, String> get headers {
    final headers = <String, String>{};
    if (!isProduction) {
      headers['X-Environment'] = _environment.name;
      headers['X-Debug-Mode'] = 'true';
    }
    return headers;
  }

  static String get appName {
    switch (_environment) {
      case Environment.production:
        return 'Gruve';
      case Environment.staging:
        return 'Gruve (Staging)';
      case Environment.development:
        return 'Gruve (Dev)';
    }
  }

  static String get appVersion {
    const version = String.fromEnvironment(
      'APP_VERSION',
      defaultValue: '1.0.0',
    );
    final buildNumber = String.fromEnvironment(
      'BUILD_NUMBER',
      defaultValue: '1',
    );
    return isProduction
        ? version
        : '$version+$buildNumber (${_environment.name})';
  }

  static bool isFeatureEnabled(String featureName) {
    final featureFlags = {
      'new_feed_ui': isDevelopment || isStaging,
      'advanced_filters': isDevelopment,
      'beta_features': isDevelopment,
      'analytics': !isDevelopment,
      'crash_reporting': _enableCrashReporting,
    };
    return featureFlags[featureName] ?? false;
  }

  static void logEnvironmentInfo() {
    if (!_enableLogging) return;

    debugPrint('[Environment] Configuration:');
    debugPrint('  Environment: ${_environment.name}');
    debugPrint('  Base URL configured: ${_baseUrl.isNotEmpty}');
    debugPrint('  WebSocket URL configured: ${_wsUrl.isNotEmpty}');
    debugPrint('  Logging: $_enableLogging');
    debugPrint('  Debug Tools: $_enableDebugTools');
    debugPrint('  Crash Reporting: $_enableCrashReporting');
    debugPrint('  API Timeout: ${_apiTimeout}s');
    debugPrint('  WebSocket Timeout: ${_wsTimeout}s');
    debugPrint('  App Name: $appName');
    debugPrint('  App Version: $appVersion');
  }
}

enum Environment { development, staging, production }

extension EnvironmentExtension on Environment {
  String get name {
    switch (this) {
      case Environment.development:
        return 'development';
      case Environment.staging:
        return 'staging';
      case Environment.production:
        return 'production';
    }
  }

  String get displayName {
    switch (this) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }
}
