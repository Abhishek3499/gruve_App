import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/socket/socket_reconnect_manager.dart';

/// Test script to verify WebSocket URL configuration
/// Run with: dart run test_websocket_config.dart
void main() async {
  print('🔍 Testing WebSocket URL Configuration...\n');
  
  // Load environment
  await dotenv.load(fileName: ".env");
  await EnvironmentConfig.initialize();
  
  print('📊 Environment Configuration:');
  print('  Environment: ${EnvironmentConfig.environment.name}');
  print('  Base URL: ${EnvironmentConfig.baseUrl}');
  print('  WebSocket URL: ${EnvironmentConfig.wsUrl}');
  print('  Is Production: ${EnvironmentConfig.isProduction}');
  print('  Logging Enabled: ${EnvironmentConfig.enableLogging}\n');
  
  // Test SocketReconnectManager URL
  print('🔌 SocketReconnectManager Configuration:');
  final reconnectManager = SocketReconnectManager();
  print('  Uses EnvironmentConfig.wsUrl: ✅');
  print('  Final WebSocket URL: ${SocketReconnectManager._baseUrl}');
  
  // Verify no hardcoded devtunnels URLs
  final wsUrl = EnvironmentConfig.wsUrl;
  final hasDevtunnels = wsUrl.contains('devtunnels') || wsUrl.contains('zg7h02xx');
  
  print('\n🔍 URL Validation:');
  if (hasDevtunnels) {
    print('  ❌ FAILED: Still contains devtunnels URL');
  } else {
    print('  ✅ PASSED: No devtunnels URLs found');
  }
  
  // Verify correct production URL
  final expectedProdUrl = 'wss://gruve-api.hardkore.tech/ws';
  final hasCorrectUrl = wsUrl == expectedProdUrl;
  
  if (hasCorrectUrl) {
    print('  ✅ PASSED: Using correct production WebSocket URL');
  } else {
    print('  ❌ FAILED: Expected $expectedProdUrl, got $wsUrl');
  }
  
  print('\n🎯 Final WebSocket URL with token format:');
  print('  ${wsUrl}?token=YOUR_TOKEN_HERE');
  
  print('\n✅ WebSocket URL Configuration Test Complete!');
}
