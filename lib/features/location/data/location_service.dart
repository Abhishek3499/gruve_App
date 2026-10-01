import 'package:dio/dio.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/location/domain/place_suggestion.dart';

/// Geoapify place autocomplete. Uses a plain Dio so the app's auth
/// interceptors never see the third-party request.
class LocationService {
  LocationService._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.geoapify.com/v1/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static Future<List<PlaceSuggestion>> search(
    String query, {
    CancelToken? cancelToken,
  }) async {
    final text = query.trim();
    if (text.length < 2) return [];

    final key = EnvironmentConfig.geoapifyApiKey;
    if (key.isEmpty) {
      AppLogger.d('LocationService: GEOAPIFY_API_KEY missing in .env');
      return [];
    }

    final response = await _dio.get(
      'geocode/autocomplete',
      queryParameters: {'text': text, 'limit': 8, 'apiKey': key},
      cancelToken: cancelToken,
    );

    final features = (response.data?['features'] as List?) ?? const [];
    return features
        .map((f) => (f as Map)['properties'])
        .whereType<Map>()
        .map((p) => PlaceSuggestion.fromGeoapify(Map<String, dynamic>.from(p)))
        .where((p) => p.formatted.isNotEmpty)
        .toList();
  }
}
