import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:gruve_app/screens/auth/token_storage.dart';

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
    debugPrint('🚀 [ApiClient] GET → $url');
    
    // Get authentication token like other API services
    final token = await TokenStorage.getAccessToken();
    debugPrint('🔑 [ApiClient] auth token: ${token?.isNotEmpty == true ? 'present' : 'missing'}');
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // Add authorization header if token is available
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await http.get(Uri.parse(url), headers: headers);
    debugPrint('📡 [ApiClient] Response ← status: ${response.statusCode}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('❌ [ApiClient] Failed: ${response.statusCode} ${response.body}');
    }
  }
}
