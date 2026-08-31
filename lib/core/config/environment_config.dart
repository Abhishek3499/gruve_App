import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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

    AppLogger.d('[Environment] Initialized: ${_environment.name}');
  }

  static Environment _parseEnvironment(String env) {
    switch (env.toLowerCase()) {
      case 'production':
      case 'prod':
        return Environment.production;
      case 'staging':
      case 'stage':
        return Environment.staging;
      case 'local':
        return Environment.local;
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
      case Environment.local:
        _baseUrl = _envValue('LOCAL_BASE_URL', fallbackKey: 'BASE_URL');
        _wsUrl = _envValue('LOCAL_WS_URL', fallbackKey: 'WS_URL');
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
  static String get googleWebClientId {
    final clientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
    if (clientId == null || clientId.isEmpty) {
      throw StateError(
        '[Environment] Missing GOOGLE_WEB_CLIENT_ID in .env. '
        'Use the OAuth 2.0 Web application client ID as GoogleSignIn.serverClientId.',
      );
    }

    if (!clientId.endsWith('.apps.googleusercontent.com')) {
      throw StateError(
        '[Environment] GOOGLE_WEB_CLIENT_ID must be a Google OAuth client ID ending with '
        '.apps.googleusercontent.com.',
      );
    }

    return clientId;
  }

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  static bool get isLocal => _environment == Environment.local;
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
      case Environment.local:
        return 'Gruve (Local)';
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
      'new_feed_ui': isDevelopment || isStaging || isLocal,
      'advanced_filters': isDevelopment || isLocal,
      'beta_features': isDevelopment || isLocal,
      'analytics': !isDevelopment && !isLocal,
      'crash_reporting': _enableCrashReporting,
    };
    return featureFlags[featureName] ?? false;
  }

  static void logEnvironmentInfo() {
    if (!_enableLogging) return;

    AppLogger.d('[Environment] Configuration:');
    AppLogger.d('  Environment: ${_environment.name}');
    AppLogger.d('  Base URL configured: ${_baseUrl.isNotEmpty}');
    AppLogger.d('  WebSocket URL configured: ${_wsUrl.isNotEmpty}');
    AppLogger.d('  Logging: $_enableLogging');
    AppLogger.d('  Debug Tools: $_enableDebugTools');
    AppLogger.d('  Crash Reporting: $_enableCrashReporting');
    AppLogger.d('  API Timeout: ${_apiTimeout}s');
    AppLogger.d('  WebSocket Timeout: ${_wsTimeout}s');
    AppLogger.d('  App Name: $appName');
    AppLogger.d('  App Version: $appVersion');
  }
}

enum Environment { development, staging, production, local }

extension EnvironmentExtension on Environment {
  String get name {
    switch (this) {
      case Environment.development:
        return 'development';
      case Environment.staging:
        return 'staging';
      case Environment.production:
        return 'production';
      case Environment.local:
        return 'local';
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
      case Environment.local:
        return 'Local';
    }
  }
}
