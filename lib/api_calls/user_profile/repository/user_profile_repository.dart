import 'package:gruve_app/api_calls/profile/repository/profile_repository.dart';
import 'package:gruve_app/api_calls/user_profile/services/user_profile_service.dart';

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
  }) {
    return _service.getUserProfile(
      userId: userId,
      allPage: allPage,
      allLimit: allLimit,
      trendingPage: trendingPage,
      trendingLimit: trendingLimit,
      likedPage: likedPage,
      likedLimit: likedLimit,
    );
  }
}
