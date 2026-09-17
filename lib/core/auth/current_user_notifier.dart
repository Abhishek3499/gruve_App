import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/profile/data/datasource/profile_services.dart';
import 'package:gruve_app/features/profile/domain/entities/profile_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Immutable state for [CurrentUserNotifier]: the current user's profile
/// summary (avatar, username, unread notification count) plus its loading flag.
@immutable
class CurrentUserState {
  const CurrentUserState({
    this.profileImageUrl,
    this.username,
    this.unreadNotificationCount = 0,
    this.isLoading = false,
  });

  final String? profileImageUrl;
  final String? username;
  final int unreadNotificationCount;
  final bool isLoading;

  CurrentUserState copyWith({bool? isLoading}) {
    return CurrentUserState(
      profileImageUrl: profileImageUrl,
      username: username,
      unreadNotificationCount: unreadNotificationCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Replaces the previous `CurrentUserProvider` (ChangeNotifier). Provides the
/// current user's profile summary for widgets outside the Profile feature
/// (nav bar avatar, home eager-load bridge) and feeds the unread notification
/// count directly to `NotificationNotifier`, which listens to this provider.
class CurrentUserNotifier extends Notifier<CurrentUserState> {
  final ProfileService _profileService = ProfileService();

  @override
  CurrentUserState build() => const CurrentUserState();

  /// Fetches current user's profile data
  Future<void> fetchCurrentUserProfile() async {
    if (state.isLoading) return;
    final cachedImage = state.profileImageUrl;
    if (cachedImage != null && cachedImage.trim().isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      AppLogger.d('🔄 [CurrentUserNotifier] Fetching user profile...');
      final profileData = await _profileService.getUser();

      AppLogger.d(
        '🔍 [CurrentUserNotifier] Profile data keys: ${profileData.keys.toList()}',
      );

      // Extract profile image URL and username securely using ProfileModel parsing
      final parsedProfile = ProfileModel.fromJson(profileData);
      state = CurrentUserState(
        profileImageUrl: parsedProfile.profileImage,
        username: parsedProfile.username,
        unreadNotificationCount: parsedProfile.unreadNotificationCount,
        isLoading: false,
      );

      AppLogger.d(
        '✅ [CurrentUserNotifier] Profile fetched - Image: ${state.profileImageUrl}',
      );
      AppLogger.d('✅ [CurrentUserNotifier] Username: ${state.username}');
      AppLogger.d(
        '✅ [CurrentUserNotifier] Unread Notifications Count: ${state.unreadNotificationCount}',
      );
    } catch (e) {
      AppLogger.d('❌ [CurrentUserNotifier] Failed to fetch profile: $e');
      state = const CurrentUserState();
    }
  }

  /// Resets profile data (call on logout)
  void reset() {
    state = const CurrentUserState();
  }

  /// Updates profile image URL (call after profile update)
  void updateProfileImage(String? imageUrl) {
    state = CurrentUserState(
      profileImageUrl: imageUrl,
      username: state.username,
      unreadNotificationCount: state.unreadNotificationCount,
      isLoading: state.isLoading,
    );
  }

  /// Updates profile data (call after profile update)
  void updateProfileData({String? username, String? imageUrl}) {
    state = CurrentUserState(
      profileImageUrl: imageUrl ?? state.profileImageUrl,
      username: username ?? state.username,
      unreadNotificationCount: state.unreadNotificationCount,
      isLoading: state.isLoading,
    );
  }
}

final currentUserNotifierProvider =
    NotifierProvider<CurrentUserNotifier, CurrentUserState>(
      CurrentUserNotifier.new,
    );
