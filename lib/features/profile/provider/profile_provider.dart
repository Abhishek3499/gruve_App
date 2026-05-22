import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/profile/data/api_calls/controller/profile_controller.dart';
import 'package:gruve_app/features/profile/data/api_calls/model/profile_model.dart';
import 'package:gruve_app/features/profile/data/api_calls/model/profile_stats_model.dart';
import 'package:gruve_app/features/highlights/api/highlight_service.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/auth/api/models/edit_profile_response.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    ProfileController? controller,
    HighlightService? highlightService,
  }) : controller = controller ?? ProfileController(),
       _highlightService = highlightService ?? HighlightService();

  final ProfileController controller;
  final HighlightService _highlightService;

  /// False until a fetch actually starts — avoids "loading forever" when no request runs.
  bool isLoading = false;
  String? errorMessage;

  Future<void>? _profileFetchInFlight;
  DateTime? _profileFetchStartedAt;
  int _profileFetchGeneration = 0;

  ProfileModel? user;
  ProfileStatsModel stats = const ProfileStatsModel.empty();
  List<Post> posts = const [];
  List<HighlightModel> highlights = const [];

  Listenable get contentListenable => controller.contentListenable;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<void> fetchProfileData({
    String fetchUserReason = 'profile_provider_opened',
  }) async {
    final inFlight = _profileFetchInFlight;
    if (inFlight != null) {
      final startedAt = _profileFetchStartedAt;
      final isStale = startedAt != null &&
          DateTime.now().difference(startedAt) > const Duration(seconds: 25);
      if (!isStale) return inFlight;

      _log('[Profile] Clearing stale in-flight fetch');
      _profileFetchInFlight = null;
      _profileFetchStartedAt = null;
      isLoading = false;
      notifyListeners();
    }

    final generation = ++_profileFetchGeneration;
    final future = _runProfileFetch(fetchUserReason: fetchUserReason);
    _profileFetchInFlight = future;
    _profileFetchStartedAt = DateTime.now();
    try {
      await future;
    } finally {
      if (_profileFetchGeneration == generation) {
        _profileFetchInFlight = null;
        _profileFetchStartedAt = null;
      }
    }
  }

  Future<void> _runProfileFetch({required String fetchUserReason}) async {
    _log('[Profile] Fetch start');

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        controller
            .fetchUser(reason: fetchUserReason)
            .timeout(const Duration(seconds: 20)),
        _highlightService
            .fetchMyHighlights()
            .timeout(const Duration(seconds: 20)),
      ]).timeout(const Duration(seconds: 25));

      final highlightsResponse = results[1] as HighlightsResponse;

      user = controller.user;
      if (user == null) {
        throw StateError('Profile API did not return user data');
      }

      stats = controller.stats;
      posts = List<Post>.unmodifiable(controller.getPostsForTab(0));
      highlights = List<HighlightModel>.unmodifiable(
        highlightsResponse.success
            ? highlightsResponse.data.highlights
            : const [],
      );

      _log('[Profile] API success');
      _log('[Profile] Highlights count: ${highlights.length}');
      _log('[Profile] Posts count: ${posts.length}');
    } catch (error, stackTrace) {
      errorMessage = 'Failed to load profile';
      _log('[Profile] API failed: $error');
      _log('$stackTrace');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfileData({String reason = 'manual_refresh'}) {
    if (_profileFetchInFlight != null) {
      _profileFetchInFlight = null;
      _profileFetchStartedAt = null;
      _profileFetchGeneration++;
    }
    return fetchProfileData(fetchUserReason: reason);
  }

  Future<void> ensureTabLoaded(int tabIndex) async {
    await controller.ensureTabLoaded(tabIndex);
    posts = List<Post>.unmodifiable(controller.getPostsForTab(0));
    notifyListeners();
  }

  void requestLoadMoreThrottled(int tabIndex) {
    controller.requestLoadMoreThrottled(tabIndex);
  }

  bool canLoadMoreForTab(int tabIndex) {
    return controller.canLoadMoreForTab(tabIndex);
  }

  void applyUpdatedProfile(EditProfileResponse response) {
    final currentUser = controller.user;
    final updated = response.data;

    if (currentUser == null) return;

    controller.user = ProfileModel(
      id: updated.userId ?? currentUser.id,
      fullName: updated.fullName.trim().isEmpty
          ? currentUser.fullName
          : updated.fullName,
      username: updated.username.trim().isEmpty
          ? currentUser.username
          : updated.username,
      profileImage: (updated.profilePicture ?? '').trim().isEmpty
          ? currentUser.profileImage
          : updated.profilePicture!,
      isFollowing: currentUser.isFollowing,
      hasActiveStory: currentUser.hasActiveStory,
      storyCount: currentUser.storyCount,
    );
    user = controller.user;
    notifyListeners();
  }

  /// Refresh profile data (used on login)
  Future<void> refreshProfile() async {
    debugPrint('🔄 [ProfileProvider] Refreshing profile data...');
    await fetchProfileData(fetchUserReason: 'login_refresh');
    debugPrint('✅ [ProfileProvider] refreshProfile completed');
  }

  /// Reset all profile data on logout
  void reset() {
    debugPrint('🔄 [ProfileProvider] Resetting profile data...');
    controller.reset();
    user = null;
    stats = const ProfileStatsModel.empty();
    posts = [];
    highlights = [];
    isLoading = false;
    _profileFetchInFlight = null;
    _profileFetchStartedAt = null;
    _profileFetchGeneration++;
    errorMessage = null;
    notifyListeners();
    debugPrint('✅ [ProfileProvider] Profile data reset complete');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
