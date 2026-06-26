import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:gruve_app/features/highlights/controller/highlight_state_manager.dart';
import 'package:gruve_app/features/profile/data/api_calls/controller/profile_controller.dart';
import 'package:gruve_app/features/profile/data/api_calls/model/profile_model.dart';
import 'package:gruve_app/features/profile/data/api_calls/model/profile_stats_model.dart';
import 'package:gruve_app/features/highlights/api/highlight_service.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/auth/api/models/edit_profile_response.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    ProfileController? controller,
    HighlightService? highlightService,
    HighlightStateManager? highlightStateManager,
  }) : controller =
           controller ??
           ProfileController(highlightStateManager: highlightStateManager),
       _highlightService = highlightService ?? HighlightService();

  final ProfileController controller;
  final HighlightService _highlightService;

  /// False until a fetch actually starts — avoids "loading forever" when no request runs.
  bool isLoading = false;
  String? errorMessage;

  CancelToken? _cancelToken;

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Profile screen disposed');
    _cancelToken = null;
    controller.cancelActiveRequests();
  }

  Future<void>? _profileFetchInFlight;
  DateTime? _profileFetchStartedAt;
  DateTime? _lastProfileFetch;
  DateTime? _lastHighlightsFetch;
  int _profileFetchGeneration = 0;
  bool _isFetchingHighlights = false;

  ProfileModel? user;
  ProfileModel? get profile => user;
  ProfileStatsModel stats = const ProfileStatsModel.empty();
  List<Post> posts = const [];
  List<HighlightModel> highlights = const [];

  Listenable get contentListenable => controller.contentListenable;

  /// NEW: Check if cached profile is fresh (call this synchronously)
  bool get hasFreshProfile {
    if (user == null || _lastProfileFetch == null) return false;
    final age = DateTime.now().difference(_lastProfileFetch!);
    return age < const Duration(minutes: 5);
  }

  /// NEW: Get cached user immediately (no async)
  ProfileModel? get cachedUser => user;

  void _log(String message) {
    AppLogger.d(message);
  }

  Future<void> fetchProfileData({
    String fetchUserReason = 'profile_provider_opened',
    bool force = false,
  }) async {
    final inFlight = _profileFetchInFlight;
    if (inFlight != null) {
      final startedAt = _profileFetchStartedAt;
      final isStale =
          startedAt != null &&
          DateTime.now().difference(startedAt) > const Duration(seconds: 25);
      if (!isStale) return inFlight;

      _log('[Profile] Clearing stale in-flight fetch');
      _profileFetchInFlight = null;
      _profileFetchStartedAt = null;
      isLoading = false;
      notifyListeners();
    }

    final generation = ++_profileFetchGeneration;
    final future = _runProfileFetch(
      fetchUserReason: fetchUserReason,
      force: force,
    );
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

  Future<void> _runProfileFetch({
    required String fetchUserReason,
    bool force = false,
    bool avatarOnly = false,
  }) async {
    _log('[Profile] Fetch start (avatarOnly=$avatarOnly)');

    final now = DateTime.now();
    final shouldFetchProfile =
        force ||
        user == null ||
        _lastProfileFetch == null ||
        now.difference(_lastProfileFetch!) >= const Duration(minutes: 5);

    final shouldFetchHighlights =
        !avatarOnly &&
        (force ||
        _lastHighlightsFetch == null ||
        now.difference(_lastHighlightsFetch!) >= const Duration(minutes: 5));

    if (!shouldFetchProfile && !shouldFetchHighlights) {
      _log('[Profile] Both profile and highlights are fresh. Skipping fetch.');
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final futures = <Future<void>>[];
      if (shouldFetchProfile) {
        futures.add(
          controller
              .fetchUser(reason: fetchUserReason)
              .timeout(const Duration(seconds: 8))
              .then((_) {
                _lastProfileFetch = DateTime.now();
                user = controller.user;
                
                // Pre-cache avatar after successful fetch
                if (user != null) {
                  unawaited(_precacheUserAvatar(user!));
                }
              }),
        );
      }
      if (shouldFetchHighlights) {
        futures.add(_loadHighlights());
      }

      await Future.wait(futures);

      if (shouldFetchProfile) {
        user = controller.user;
        if (user == null) {
          throw StateError('Profile API did not return user data');
        }

        stats = controller.stats;
        posts = List<Post>.unmodifiable(controller.getPostsForTab(0));
      }

      _log('[Profile] API success');
      if (shouldFetchProfile) {
        _log('[Profile] Posts count: ${posts.length}');
      }
    } catch (error, stackTrace) {
      if (error is TimeoutException) {
        errorMessage = 'Profile load timeout. Check your connection.';
      } else {
        errorMessage = 'Failed to load profile';
      }
      _log('[Profile] API failed: $error');
      _log('$stackTrace');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadHighlights() async {
    if (_isFetchingHighlights) return;

    _isFetchingHighlights = true;
    try {
      final response = await _highlightService
          .fetchMyHighlights(cancelToken: _getCancelToken())
          .timeout(const Duration(seconds: 12));
      highlights = List<HighlightModel>.unmodifiable(
        response.success ? response.data.highlights : const [],
      );
      controller.highlightList.value = highlights;
      _log('[Profile] Highlights count: ${highlights.length}');

      if (response.success) {
        _lastHighlightsFetch = DateTime.now();
      }

      unawaited(_precacheHighlightCovers(highlights));
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) {
        AppLogger.d('[ProfileProvider] Highlights cancelled');
        return;
      }
      _log('[Profile] Highlights failed: $error');
    } finally {
      _isFetchingHighlights = false;
    }
  }

  Future<void> _precacheHighlightCovers(List<HighlightModel> list) async {
    final futures = <Future<void>>[];
    for (final highlight in list) {
      final cover = _coverFor(highlight);
      if (cover != null && cover.startsWith('http')) {
        final completer = Completer<void>();
        final provider = CachedNetworkImageProvider(cover);
        final stream = provider.resolve(ImageConfiguration.empty);
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (info, synchronousCall) {
            if (!completer.isCompleted) {
              completer.complete();
            }
            stream.removeListener(listener);
          },
          onError: (exception, stackTrace) {
            if (!completer.isCompleted) {
              completer.complete();
            }
            stream.removeListener(listener);
          },
        );
        stream.addListener(listener);
        futures.add(
          completer.future.timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
          ),
        );
      }
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  String? _coverFor(HighlightModel highlight) {
    if (highlight.coverMediaUrl.trim().isNotEmpty) {
      return highlight.coverMediaUrl.trim();
    }
    if (highlight.stories.isNotEmpty &&
        highlight.stories.first.mediaUrl.trim().isNotEmpty) {
      return highlight.stories.first.mediaUrl.trim();
    }
    return null;
  }

  Future<void> refreshProfileData({String reason = 'manual_refresh'}) {
    if (_profileFetchInFlight != null) {
      _profileFetchInFlight = null;
      _profileFetchStartedAt = null;
      _profileFetchGeneration++;
    }
    return fetchProfileData(fetchUserReason: reason, force: true);
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
    AppLogger.d('🔄 [ProfileProvider] Refreshing profile data...');
    await fetchProfileData(fetchUserReason: 'login_refresh', force: true);
    AppLogger.d('✅ [ProfileProvider] refreshProfile completed');
  }

  /// Reset all profile data on logout
  void reset() {
    AppLogger.d('🔄 [ProfileProvider] Resetting profile data...');
    controller.reset();
    user = null;
    stats = const ProfileStatsModel.empty();
    posts = [];
    highlights = [];
    controller.highlightList.value = const [];
    isLoading = false;
    _isFetchingHighlights = false;
    _profileFetchInFlight = null;
    _profileFetchStartedAt = null;
    _lastProfileFetch = null;
    _lastHighlightsFetch = null;
    _profileFetchGeneration++;
    errorMessage = null;
    notifyListeners();
    AppLogger.d('✅ [ProfileProvider] Profile data reset complete');
  }

  /// Remove highlight locally from the UI state
  void removeHighlightLocally(String highlightId) {
    final updated = highlights.where((h) => h.id != highlightId).toList();
    highlights = List<HighlightModel>.unmodifiable(updated);
    controller.highlightList.value = highlights;
    notifyListeners();
  }

  /// NEW: Quick fetch for avatar only (skip highlights)
  Future<void> fetchAvatarOnly() async {
    return _runProfileFetch(
      fetchUserReason: 'avatar_only',
      avatarOnly: true,
    );
  }

  /// NEW: Pre-cache avatar after profile fetch
  Future<void> _precacheUserAvatar(ProfileModel user) async {
    final imageUrl = user.profileImage.trim();
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) return;
    
    try {
      final provider = CachedNetworkImageProvider(imageUrl);
      final stream = provider.resolve(ImageConfiguration.empty);
      final completer = Completer<void>();
      
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, synchronousCall) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          stream.removeListener(listener);
        },
        onError: (exception, stackTrace) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          stream.removeListener(listener);
        },
      );
      
      stream.addListener(listener);
      await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
      
      AppLogger.d('✅ [ProfileProvider] Pre-cached user avatar');
    } catch (e) {
      AppLogger.d('⚠️ [ProfileProvider] Avatar pre-cache failed: $e');
    }
  }

  @override
  void dispose() {
    cancelActiveRequests();
    controller.dispose();
    super.dispose();
  }
}
