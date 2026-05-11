import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'dart:developer' as developer;

class ApiClient {
  late final String _baseUrl;

  ApiClient() {
    _baseUrl = (dotenv.env['BASE_URL'] ?? '').trim();
    if (_baseUrl.isEmpty) {
      throw Exception('[ApiClient] BASE_URL is missing in .env file');
    }
    debugPrint('🌐 [ApiClient] Initialized with BASE_URL: $_baseUrl');
  }

  Future<dynamic> get(String endpoint) async {
    final url = '$_baseUrl$endpoint';
    final requestStart = DateTime.now();
    debugPrint('🚀 [ApiClient] GET → $url');
    
    // Get authentication token like other API services
    final tokenStart = DateTime.now();
    final token = await TokenStorage.getAccessToken();
    final tokenTime = DateTime.now().difference(tokenStart);
    developer.log('🔑 [PERF] Token retrieval took ${tokenTime.inMilliseconds}ms', name: 'ApiClient');
    debugPrint('🔑 [ApiClient] auth token: ${token?.isNotEmpty == true ? 'present' : 'missing'}');
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // Add authorization header if token is available
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final networkStart = DateTime.now();
    final response = await http.get(Uri.parse(url), headers: headers);
    final networkTime = DateTime.now().difference(networkStart);
    final totalTime = DateTime.now().difference(requestStart);
    
    developer.log('🌐 [PERF] API GET $endpoint: Network ${networkTime.inMilliseconds}ms, Total ${totalTime.inMilliseconds}ms', name: 'ApiClient');
    debugPrint('📡 [ApiClient] Response ← status: ${response.statusCode}');
    
    // Track performance metrics
    if (totalTime.inMilliseconds > 2000) {
      developer.log('⚠️ [PERF] Slow API call: $endpoint took ${totalTime.inMilliseconds}ms', name: 'ApiClient');
    }
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('❌ [ApiClient] Failed: ${response.statusCode} ${response.body}');
    }
  }
}
