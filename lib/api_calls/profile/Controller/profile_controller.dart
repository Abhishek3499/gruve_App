import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/profile/services/profile_services.dart';

import '../model/profile_model.dart';
import '../model/profile_stats_model.dart';

class ProfileController {
  final ProfileService _service = ProfileService();

  ValueNotifier<bool> isLoading = ValueNotifier(false);

  ProfileModel? user;
  ProfileStatsModel? stats;

  Future<void> fetchUser() async {
    try {
      debugPrint("🔵 Profile API Called");
      isLoading.value = true;

      final data = await _service.getUser();

      final userData = data["user"] ?? data;
      user = ProfileModel.fromJson(userData);
      stats = ProfileStatsModel.fromJson(data);

      debugPrint("✅ USER: ${user?.fullName}");
      debugPrint("✅ STATS: Subscribers: ${stats?.subscribersCount}, Likes: ${stats?.likesCount}, Videos: ${stats?.videosCount}");
    } catch (e) {
      debugPrint("❌ ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

