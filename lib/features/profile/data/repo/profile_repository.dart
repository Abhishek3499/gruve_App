import 'package:dio/dio.dart';
import 'package:gruve_app/features/profile/data/datasource/profile_services.dart';

class ProfileRepository {
  final ProfileService _service;

  ProfileRepository({ProfileService? service})
      : _service = service ?? ProfileService();

  Future<Map<String, dynamic>> fetchProfileData({
    int? allPage,
    int? allLimit,
    int? trendingPage,
    int? trendingLimit,
    int? likedPage,
    int? likedLimit,
    CancelToken? cancelToken,
  }) {
    return _service.getUser(
      allPage: allPage,
      allLimit: allLimit,
      trendingPage: trendingPage,
      trendingLimit: trendingLimit,
      likedPage: likedPage,
      likedLimit: likedLimit,
      cancelToken: cancelToken,
    );
  }
}
