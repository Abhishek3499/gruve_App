import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// ⚙️ EnvironmentConfig
/// Reads environment variables from `.env` file cleanly and provides easy app-wide getters.
class EnvironmentConfig {
  EnvironmentConfig._();

  static late String _baseUrl;
  static late String _wsUrl;
  static late String _googleWebClientId;
  static bool _isInitialized = false;

  /// 🚀 Initialize and load .env values
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
    }

    _baseUrl = dotenv.env['BASE_URL']?.trim() ?? 'https://gruve-api.hardkore.tech/api/v1/';
    _wsUrl = dotenv.env['WS_URL']?.trim() ?? 'wss://gruve-api.hardkore.tech/ws';
    _googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';

    _isInitialized = true;
    AppLogger.d('⚙️ [EnvironmentConfig] Initialized successfully with Base URL: $_baseUrl');
  }

  // ==========================================
  // Public Getters
  // ==========================================

  /// REST API Base URL
  static String get baseUrl => _baseUrl;

  /// WebSocket URL
  static String get wsUrl => _wsUrl;

  /// Google OAuth Web Client ID for Sign-In
  static String get googleWebClientId {
    if (_googleWebClientId.isEmpty) {
      _googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';
    }
    return _googleWebClientId;
  }

  /// App Timeout defaults (in seconds)
  static const int apiTimeout = 30;
  static const int wsTimeout = 15;
}
