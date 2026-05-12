import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration management
/// Handles dev/staging/prod environments using dart-define
class EnvironmentConfig {
  static late Environment _environment;
  static late String _baseUrl;
  static late String _wsUrl;
  static late bool _enableLogging;
  static late bool _enableDebugTools;
  static late bool _enableCrashReporting;
  static late int _apiTimeout;
  static late int _wsTimeout;

  /// Initialize environment configuration
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    
    // Detect environment from dart-define
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    _environment = _parseEnvironment(environment);
    
    // Load configuration based on environment
    _loadConfiguration();
    
    debugPrint('🌍 [Environment] Initialized: ${_environment.name}');
    debugPrint('🔗 [Environment] Base URL: $_baseUrl');
    debugPrint('📊 [Environment] Logging enabled: $_enableLogging');
  }

  /// Parse environment string
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

  /// Load configuration for current environment
  static void _loadConfiguration() {
    switch (_environment) {
      case Environment.production:
        _baseUrl = dotenv.env['PROD_BASE_URL'] ?? 'https://gruve-api.hardkore.tech/api/v1';
        _wsUrl = dotenv.env['PROD_WS_URL'] ??  'wss://gruve-api.hardkore.tech/ws';
        _enableLogging = false;
        _enableDebugTools = false;
        _enableCrashReporting = true;
        _apiTimeout = 30;
        _wsTimeout = 15;
        break;
        
      case Environment.staging:
        _baseUrl = dotenv.env['STAGING_BASE_URL'] ?? 'https://staging-api.gruveapp.com';
        _wsUrl = dotenv.env['STAGING_WS_URL'] ?? 'wss://staging-ws.gruveapp.com';
        _enableLogging = true;
        _enableDebugTools = false;
        _enableCrashReporting = true;
        _apiTimeout = 25;
        _wsTimeout = 12;
        break;
        
      case Environment.development:
      default:
        _baseUrl = dotenv.env['DEV_BASE_URL'] ?? 'http://localhost:8000';
        _wsUrl = dotenv.env['DEV_WS_URL'] ?? 'ws://localhost:8000';
        _enableLogging = true;
        _enableDebugTools = true;
        _enableCrashReporting = false;
        _apiTimeout = 20;
        _wsTimeout = 10;
        break;
    }
  }

  // =========================
  // GETTERS
  // =========================

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

  /// Get environment-specific headers
  static Map<String, String> get headers {
    final headers = <String, String>{};
    
    if (!isProduction) {
      headers['X-Environment'] = _environment.name;
      headers['X-Debug-Mode'] = 'true';
    }
    
    return headers;
  }

  /// Get environment-specific app name
  static String get appName {
    switch (_environment) {
      case Environment.production:
        return 'Gruve';
      case Environment.staging:
        return 'Gruve (Staging)';
      case Environment.development:
      default:
        return 'Gruve (Dev)';
    }
  }

  /// Get environment-specific app version
  static String get appVersion {
    const version = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
    final buildNumber = String.fromEnvironment('BUILD_NUMBER', defaultValue: '1');
    
    if (isProduction) {
      return version;
    } else {
      return '$version+$buildNumber (${_environment.name})';
    }
  }

  /// Check if feature is enabled
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

  /// Log environment info
  static void logEnvironmentInfo() {
    if (!_enableLogging) return;
    
    debugPrint('🌍 [Environment] Configuration:');
    debugPrint('  Environment: ${_environment.name}');
    debugPrint('  Base URL: $_baseUrl');
    debugPrint('  WebSocket URL: $_wsUrl');
    debugPrint('  Logging: $_enableLogging');
    debugPrint('  Debug Tools: $_enableDebugTools');
    debugPrint('  Crash Reporting: $_enableCrashReporting');
    debugPrint('  API Timeout: ${_apiTimeout}s');
    debugPrint('  WebSocket Timeout: ${_wsTimeout}s');
    debugPrint('  App Name: $appName');
    debugPrint('  App Version: $appVersion');
  }
}

/// Environment enum
enum Environment {
  development,
  staging,
  production,
}

/// Extension for environment utilities
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
