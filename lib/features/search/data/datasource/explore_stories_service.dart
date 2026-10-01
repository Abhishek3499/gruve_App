import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
import 'package:gruve_app/features/search/domain/entities/explore_story_model.dart';

class ExploreStoriesService {
  ExploreStoriesService({Dio? dio}) : _dio = dio ?? AppDio.getInstance();

  final Dio _dio;

  /// Ring state changes as stories are watched, so this never reads a cache.
  Future<ExploreStoriesData> fetchStories() async {
    final token = await TokenStorage.getAccessToken();
    final response = await _dio.get(
      ApiConstants.exploreStories,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        extra: const {'skipCache': true},
      ),
    );

    final root = response.data;
    final data = root is Map ? root['data'] : null;
    if (data is! Map) return const ExploreStoriesData();
    return ExploreStoriesData.fromJson(Map<String, dynamic>.from(data));
  }
}
