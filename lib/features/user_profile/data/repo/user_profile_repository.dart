import 'package:dio/dio.dart';
import 'package:gruve_app/features/profile/data/repo/profile_repository.dart';
import 'package:gruve_app/features/user_profile/data/datasource/user_profile_service.dart';

class UserProfileRepository extends ProfileRepository {
  final String userId;
  final UserProfileService _service;

  UserProfileRepository({
    required this.userId,
    UserProfileService? service,
  }) : _service = service ?? UserProfileService();

  @override
  Future<Map<String, dynamic>> fetchProfileData({
    int? allPage,
    int? allLimit,
    int? trendingPage,
    int? trendingLimit,
    int? likedPage,
    int? likedLimit,
    CancelToken? cancelToken,
  }) {
    return _service.getUserProfile(
      userId: userId,
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
