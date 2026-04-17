import 'package:gruve_app/api_calls/profile/services/profile_services.dart';

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
  }) {
    return _service.getUser(
      allPage: allPage,
      allLimit: allLimit,
      trendingPage: trendingPage,
      trendingLimit: trendingLimit,
      likedPage: likedPage,
      likedLimit: likedLimit,
    );
  }
}
