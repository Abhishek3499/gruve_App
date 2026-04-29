import 'package:flutter/foundation.dart';
import 'package:gruve_app/api_calls/profile/controller/profile_controller.dart';
import 'package:gruve_app/api_calls/profile/model/profile_model.dart';
import 'package:gruve_app/api_calls/profile/model/profile_stats_model.dart';
import 'package:gruve_app/features/highlights/api/highlight_service.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/screens/auth/api/models/edit_profile_response.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    ProfileController? controller,
    HighlightService? highlightService,
  }) : controller = controller ?? ProfileController(),
       _highlightService = highlightService ?? HighlightService();

  final ProfileController controller;
  final HighlightService _highlightService;

  bool isLoading = true;
  String? errorMessage;

  ProfileModel? user;
  ProfileStatsModel stats = const ProfileStatsModel.empty();
  List<Post> posts = const [];
  List<HighlightModel> highlights = const [];

  Listenable get contentListenable => controller.contentListenable;

  Future<void> fetchProfileData() async {
    debugPrint('[Profile] Fetch start');

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        controller.fetchUser(reason: 'profile_provider_opened'),
        _highlightService.fetchMyHighlights(),
      ]);

      final highlightsResponse = results[1] as HighlightsResponse;

      user = controller.user;
      stats = controller.stats;
      posts = List<Post>.unmodifiable(controller.getPostsForTab(0));
      highlights = List<HighlightModel>.unmodifiable(
        highlightsResponse.success
            ? highlightsResponse.data.highlights
            : const [],
      );

      debugPrint('[Profile] API success');
      debugPrint('[Profile] Highlights count: ${highlights.length}');
      debugPrint('[Profile] Posts count: ${posts.length}');
    } catch (error, stackTrace) {
      errorMessage = 'Failed to load profile';
      debugPrint('[Profile] API failed: $error');
      debugPrint('$stackTrace');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfileData({String reason = 'manual_refresh'}) {
    return fetchProfileData();
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
      profileImage: (updated.profile_picture ?? '').trim().isEmpty
          ? currentUser.profileImage
          : updated.profile_picture!,
      isFollowing: currentUser.isFollowing,
      hasActiveStory: currentUser.hasActiveStory,
      storyCount: currentUser.storyCount,
    );
    user = controller.user;
    notifyListeners();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
