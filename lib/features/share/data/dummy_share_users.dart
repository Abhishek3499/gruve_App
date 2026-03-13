import 'package:gruve_app/core/assets.dart';
import '../models/share_user_model.dart';

class DummyShareUsers {
  static List<ShareUserModel> getShareUsers() {
    // Using the same users from video_dummy_data.dart
    return [
      ShareUserModel(
        id: '1',
        username: 'rahul_verma',
        avatar: AppAssets.profile,
        isOnline: true,
      ),
      ShareUserModel(
        id: '2',
        username: 'neha_style',
        avatar: AppAssets.profile,
        isOnline: false,
      ),
      ShareUserModel(
        id: '3',
        username: 'tech_with_aman',
        avatar: AppAssets.profile,
        isOnline: true,
      ),
      ShareUserModel(
        id: '4',
        username: 'travel_with_me',
        avatar: AppAssets.profile,
        isOnline: false,
      ),
      ShareUserModel(
        id: '5',
        username: 'fitness_raj',
        avatar: AppAssets.profile,
        isOnline: true,
      ),
      ShareUserModel(
        id: '6',
        username: 'foodie_diaries',
        avatar: AppAssets.profile,
        isOnline: false,
      ),
      ShareUserModel(
        id: '7',
        username: 'life_of_sara',
        avatar: AppAssets.profile,
        isOnline: true,
      ),
      ShareUserModel(
        id: '8',
        username: 'rohit_gamer',
        avatar: AppAssets.profile,
        isOnline: false,
      ),
    ];
  }

  // Get filtered users based on search query
  static List<ShareUserModel> getFilteredUsers(String query) {
    if (query.isEmpty) return getShareUsers();
    
    final users = getShareUsers();
    return users.where((user) => 
      user.username.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
