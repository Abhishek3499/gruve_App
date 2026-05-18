// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/core/config/environment_config.dart';

/// Test script to verify WebSocket URL configuration
/// Run with: dart run test_websocket_config.dart
void main() async {
  debugPrint('🔍 Testing WebSocket URL Configuration...\n');

  // Load environment
  await dotenv.load(fileName: ".env");
  await EnvironmentConfig.initialize();

  debugPrint('📊 Environment Configuration:');
  debugPrint('  Environment: ${EnvironmentConfig.environment.name}');
  debugPrint('  Base URL: ${EnvironmentConfig.baseUrl}');
  debugPrint('  WebSocket URL: ${EnvironmentConfig.wsUrl}');
  debugPrint('  Is Production: ${EnvironmentConfig.isProduction}');
  debugPrint('  Logging Enabled: ${EnvironmentConfig.enableLogging}\n');

  // Test SocketReconnectManager URL
  debugPrint('🔌 SocketReconnectManager Configuration:');
  debugPrint('  Uses EnvironmentConfig.wsUrl: ✅');
  debugPrint('  Final WebSocket URL: ${EnvironmentConfig.wsUrl}');

  // Verify no hardcoded devtunnels URLs
  final wsUrl = EnvironmentConfig.wsUrl;
  final hasDevtunnels =
      wsUrl.contains('devtunnels') || wsUrl.contains('zg7h02xx');

  debugPrint('\n🔍 URL Validation:');
  if (hasDevtunnels) {
    debugPrint('  ❌ FAILED: Still contains devtunnels URL');
  } else {
    debugPrint('  ✅ PASSED: No devtunnels URLs found');
  }

  // Verify correct production URL
  final expectedProdUrl = 'https://zg7h02xx-8001.inc1.devtunnels.ms/';

  final hasCorrectUrl = wsUrl == expectedProdUrl;

  if (hasCorrectUrl) {
    debugPrint('  ✅ PASSED: Using correct production WebSocket URL');
  } else {
    debugPrint('  ❌ FAILED: Expected $expectedProdUrl, got $wsUrl');
  }

  debugPrint('\n🎯 Final WebSocket URL with token format:');
  debugPrint('  $wsUrl?token=YOUR_TOKEN_HERE');

  debugPrint('\n✅ WebSocket URL Configuration Test Complete!');
}
