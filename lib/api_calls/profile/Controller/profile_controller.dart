import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/profile/services/profile_services.dart';

import '../model/profile_model.dart';

class ProfileController {
  final ProfileService _service = ProfileService();

  ValueNotifier<bool> isLoading = ValueNotifier(false);

  ProfileModel? user;

  Future<void> fetchUser() async {
    try {
      isLoading.value = true;

      final data = await _service.getUser();
      user = ProfileModel.fromJson(data);

      debugPrint("👤 USER: ${user?.fullName}");
    } catch (e) {
      debugPrint("❌ ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
