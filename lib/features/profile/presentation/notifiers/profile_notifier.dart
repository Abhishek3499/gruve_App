import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/media/video_frame_cache.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/highlights/data/datasource/highlight_service.dart';
import 'package:gruve_app/features/highlights/domain/entities/highlight_model.dart';
import 'package:gruve_app/features/profile/data/dto/edit_profile_response.dart';
import 'package:gruve_app/features/profile/domain/entities/profile_model.dart';
import 'package:gruve_app/features/profile/domain/entities/profile_stats_model.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_controller.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';

@immutable
class ProfileState {
  const ProfileState({
    this.user,
    this.stats = const ProfileStatsModel.empty(),
    this.posts = const [],
    this.highlights = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final ProfileModel? user;
  final ProfileStatsModel stats;
  final List<Post> posts;
  final List<HighlightModel> highlights;
  final bool isLoading;
  final String? errorMessage;

  ProfileModel? get profile => user;
  ProfileModel? get cachedUser => user;

  ProfileState copyWith({
    ProfileModel? user,
    ProfileStatsModel? stats,
    List<Post>? posts,
    List<HighlightModel>? highlights,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return ProfileState(
      user: clearUser ? null : (user ?? this.user),
      stats: stats ?? this.stats,
      posts: posts ?? this.posts,
      highlights: highlights ?? this.highlights,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileState &&
        other.user == user &&
        other.stats == stats &&
        listEquals(other.posts, posts) &&
        listEquals(other.highlights, highlights) &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    user,
    stats,
    Object.hashAll(posts),
    Object.hashAll(highlights),
    isLoading,
    errorMessage,
  );
}

class ProfileNotifier extends Notifier<ProfileState> {
  ProfileNotifier({
    ProfileController? controller,
    HighlightService? highlightService,
  }) : controller = controller ?? ProfileController(),
       _highlightService = highlightService ?? HighlightService();

  late final ProfileController controller;
  final HighlightService _highlightService;

  CancelToken? _cancelToken;
  Future<void>? _profileFetchInFlight;
  DateTime? _profileFetchStartedAt;
  DateTime? _lastProfileFetch;
  DateTime? _lastHighlightsFetch;
  int _profileFetchGeneration = 0;
  bool _isFetchingHighlights = false;

  @override
  ProfileState build() {
    ref.onDispose(() {
      cancelActiveRequests();
      controller.dispose();
    });
    return const ProfileState();
  }

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Profile screen disposed');
    _cancelToken = null;
    controller.cancelActiveRequests();
  }

  ProfileModel? get user => state.user;
  ProfileModel? get profile => state.user;
  ProfileModel? get cachedUser => state.user;
  ProfileStatsModel get stats => state.stats;
  List<Post> get posts => state.posts;
  List<HighlightModel> get highlights => state.highlights;
  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;

  Listenable get contentListenable => controller.contentListenable;

  bool get hasFreshProfile {
    if (state.user == null || _lastProfileFetch == null) return false;
    final age = DateTime.now().difference(_lastProfileFetch!);
    return age < const Duration(minutes: 5);
  }

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
      state = state.copyWith(isLoading: false);
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
        state.user == null ||
        _lastProfileFetch == null ||
        now.difference(_lastProfileFetch!) >= const Duration(minutes: 5);

    final shouldFetchHighlights =
        !avatarOnly &&
        (force ||
            _lastHighlightsFetch == null ||
            now.difference(_lastHighlightsFetch!) >=
                const Duration(minutes: 5));

    if (!shouldFetchProfile && !shouldFetchHighlights) {
      _log('[Profile] Both profile and highlights are fresh. Skipping fetch.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final futures = <Future<void>>[];
      if (shouldFetchProfile) {
        futures.add(
          controller
              .fetchUser(reason: fetchUserReason)
              .timeout(const Duration(seconds: 8))
              .then((_) {
                _lastProfileFetch = DateTime.now();
                final fetchedUser = controller.user;
                state = state.copyWith(user: fetchedUser);

                // Pre-cache avatar after successful fetch
                if (fetchedUser != null) {
                  unawaited(_precacheUserAvatar(fetchedUser));
                }
              }),
        );
      }
      if (shouldFetchHighlights) {
        futures.add(_loadHighlights());
      }

      await Future.wait(futures);

      if (shouldFetchProfile) {
        final fetchedUser = controller.user;
        if (fetchedUser == null) {
          throw StateError('Profile API did not return user data');
        }

        final fetchedStats = controller.stats;
        final fetchedPosts = List<Post>.unmodifiable(
          controller.getPostsForTab(0),
        );
        state = state.copyWith(
          user: fetchedUser,
          stats: fetchedStats,
          posts: fetchedPosts,
        );
      }

      _log('[Profile] API success');
      if (shouldFetchProfile) {
        _log('[Profile] Posts count: ${state.posts.length}');
      }
    } catch (error, stackTrace) {
      final errorMsg = error is TimeoutException
          ? 'Profile load timeout. Check your connection.'
          : 'Failed to load profile';
      state = state.copyWith(errorMessage: errorMsg);
      _log('[Profile] API failed: $error');
      _log('$stackTrace');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadHighlights() async {
    if (_isFetchingHighlights) return;

    _isFetchingHighlights = true;
    try {
      final response = await _highlightService
          .fetchMyHighlights(cancelToken: _getCancelToken())
          .timeout(const Duration(seconds: 12));
      final loadedHighlights = List<HighlightModel>.unmodifiable(
        response.success ? response.data.highlights : const [],
      );
      state = state.copyWith(highlights: loadedHighlights);
      controller.highlightList.value = loadedHighlights;
      _log('[Profile] Highlights count: ${loadedHighlights.length}');

      if (response.success) {
        _lastHighlightsFetch = DateTime.now();
      }

      unawaited(_precacheHighlightCovers(loadedHighlights));
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) {
        AppLogger.d('[ProfileNotifier] Highlights cancelled');
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
      if (cover == null || !cover.startsWith('http')) continue;

      if (Post.mediaUrlLooksLikeVideo(cover)) {
        futures.add(VideoFrameCache.warmup(cover));
        continue;
      }

      futures.add(_precacheNetworkImage(cover));
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _precacheNetworkImage(String imgUrl) async {
    final completer = Completer<void>();
    final provider = CachedNetworkImageProvider(imgUrl);
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronousCall) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
      onError: (exception, stackTrace) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        if (!completer.isCompleted) completer.complete();
      },
    );
  }

  String? _coverFor(HighlightModel highlight) => highlight.coverPreviewUrl;

  Future<void> refreshProfileData({String reason = 'manual_refresh'}) {
    if (_profileFetchInFlight != null) {
      _profileFetchInFlight = null;
      _profileFetchStartedAt = null;
      _profileFetchGeneration++;
    }
    return fetchProfileData(fetchUserReason: reason, force: true);
  }

  /// Lightweight stats refresh — no loading spinner, used after likes/subscribes.
  Future<void> refreshCounts({String reason = 'counts_refresh'}) async {
    try {
      await controller.refreshCounts(reason: reason);
      _lastProfileFetch = DateTime.now();
      state = state.copyWith(user: controller.user, stats: controller.stats);
      _log('[Profile] Counts refresh success');
    } catch (error, stackTrace) {
      _log('[Profile] Counts refresh failed: $error');
      _log('$stackTrace');
    }
  }

  Future<void> ensureTabLoaded(int tabIndex) async {
    await controller.ensureTabLoaded(tabIndex);
    state = state.copyWith(
      posts: List<Post>.unmodifiable(controller.getPostsForTab(0)),
    );
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

    final updatedUser = ProfileModel(
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
    controller.user = updatedUser;
    state = state.copyWith(user: updatedUser);
  }

  /// Refresh profile data (used on login)
  Future<void> refreshProfile() async {
    AppLogger.d('🔄 [ProfileNotifier] Refreshing profile data...');
    await fetchProfileData(fetchUserReason: 'login_refresh', force: true);
    AppLogger.d('✅ [ProfileNotifier] refreshProfile completed');
  }

  /// Reset all profile data on logout
  void reset() {
    AppLogger.d('🔄 [ProfileNotifier] Resetting profile data...');
    controller.reset();
    _isFetchingHighlights = false;
    _profileFetchInFlight = null;
    _profileFetchStartedAt = null;
    _lastProfileFetch = null;
    _lastHighlightsFetch = null;
    _profileFetchGeneration++;
    state = const ProfileState();
    AppLogger.d('✅ [ProfileNotifier] Profile data reset complete');
  }

  /// Remove highlight locally from the UI state
  void removeHighlightLocally(String highlightId) {
    final updated = state.highlights.where((h) => h.id != highlightId).toList();
    final immutableList = List<HighlightModel>.unmodifiable(updated);
    controller.highlightList.value = immutableList;
    state = state.copyWith(highlights: immutableList);
  }

  /// Update highlights list directly (e.g. after adding or creating highlight)
  void updateHighlights(List<HighlightModel> highlights) {
    final immutableList = List<HighlightModel>.unmodifiable(highlights);
    controller.highlightList.value = immutableList;
    _lastHighlightsFetch = DateTime.now();
    state = state.copyWith(highlights: immutableList);
  }

  /// Force-refresh highlights from the network
  Future<void> refreshHighlights() async {
    _lastHighlightsFetch = null;
    return _loadHighlights();
  }

  /// Quick fetch for avatar only (skip highlights)
  Future<void> fetchAvatarOnly() async {
    return _runProfileFetch(fetchUserReason: 'avatar_only', avatarOnly: true);
  }

  /// Pre-cache avatar after profile fetch
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

      AppLogger.d('✅ [ProfileNotifier] Pre-cached user avatar');
    } catch (e) {
      AppLogger.d('⚠️ [ProfileNotifier] Avatar pre-cache failed: $e');
    }
  }
}

final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
