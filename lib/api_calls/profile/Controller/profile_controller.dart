import 'package:flutter/material.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/api_calls/profile/services/profile_services.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

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

      if (user != null && user!.id.trim().isNotEmpty) {
        await TokenStorage.saveCurrentUserId(user!.id);
        ProfileIdentityService.instance.primeLoggedInUserId(user!.id);
      }

      await ProfileIdentityService.instance.resolveProfileIdentity(user?.id);

      debugPrint("✅ USER: ${user?.fullName}");
      debugPrint("✅ STATS: Subscribers: ${stats?.subscribersCount}, Likes: ${stats?.likesCount}, Videos: ${stats?.videosCount}");
    } catch (e) {
      debugPrint("❌ ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

