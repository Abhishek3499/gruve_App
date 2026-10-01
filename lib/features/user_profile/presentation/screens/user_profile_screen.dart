import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/features/user_profile/presentation/controller/user_profile_controller.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/home/presentation/controllers/subscribe_notifier.dart';
import 'package:gruve_app/features/home/data/models/subscribe_model.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/features/connections/presentation/screens/connections_screen.dart';
import 'package:gruve_app/features/message/utils/conversation_utils.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/user_filter_tabs.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/user_highlights_list.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/user_profile_grid.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/user_profile_header.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/user_stats_row.dart';
import 'package:gruve_app/shared/widgets/shimmer/profile_shimmer.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String profileUserId;
  final String userName;
  final String? profileImageUrl;
  final bool initialHasActiveStory;

  const UserProfileScreen({
    super.key,
    required this.profileUserId,
    required this.userName,
    this.profileImageUrl,
    this.initialHasActiveStory = false,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  ProfileIdentityResolution? _identityResolution;
  bool _isResolvingIdentity = true;
  String? _lastLoggedInUserId;
  final ValueNotifier<int> _selectedTabNotifier = ValueNotifier<int>(0);
  late final UserProfileController _profileController;
  late final SubscribeNotifier _subscribeController;
  bool _didSeedSubscribeState = false;
  bool _isRefreshing = false;
  final ScrollController _scrollController = ScrollController();
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger(
    threshold: 360,
  );

  @override
  void initState() {
    super.initState();
    _profileController = UserProfileController(userId: widget.profileUserId);
    _subscribeController = ref.read(subscribeNotifierProvider);
    _profileController.contentListenable.addListener(_syncSubscribeState);
    _scrollController.addListener(_onProfileScroll);
    _resolveIdentity();
    // forceRefresh: this endpoint is cached (CacheConfigs.profile, up to
    // 30min disk TTL) and embeds has_active_story/has_unseen_story/
    // has_close_friends_story — a stale cache hit here would show the wrong
    // story ring the moment this profile is opened, not just until the next
    // pull-to-refresh.
    _profileController.fetchUser(forceRefresh: true);
  }

  void _onProfileScroll() {
    if (!_scrollController.hasClients) return;

    final tabIndex = _selectedTabNotifier.value == 0 ? 0 : 2;
    if (!_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: _profileController.isLoadingTab(tabIndex),
      hasMore: _profileController.canLoadMoreForTab(tabIndex),
    )) {
      return;
    }

    _profileController.requestLoadMoreThrottled(tabIndex);
  }

  void _openMessage({
    required String userId,
    required String username,
    String? profileImage,
  }) {
    if (userId.isEmpty) return;
    ConversationUtils.navigateToChat(
      context: context,
      ref: ref,
      receiverId: userId,
      receiverName: username,
      receiverProfileImage: profileImage,
      source: 'user_profile_screen',
    );
  }

  void _openConnections({required String userId, required int initialTab}) {
    if (userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ConnectionsScreen(userId: userId, initialTabIndex: initialTab),
      ),
    );
  }

  @override
  void dispose() {
    _profileController.contentListenable.removeListener(_syncSubscribeState);
    _scrollController.removeListener(_onProfileScroll);
    _scrollController.dispose();
    _selectedTabNotifier.dispose();
    _profileController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _profileController.fetchUser(
        reason: 'pull_to_refresh',
        forceRefresh: true,
      );
      AppLogger.d(
        '✅ [UserProfileScreen] Pull-to-refresh completed successfully',
      );
    } catch (e) {
      AppLogger.d('❌ [UserProfileScreen] Pull-to-refresh failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _syncSubscribeState() {
    if (_didSeedSubscribeState) {
      return;
    }

    final profile = _profileController.user;
    if (profile == null) {
      return;
    }

    final resolvedUserId = profile.id.isNotEmpty
        ? profile.id
        : widget.profileUserId;
    final resolvedUsername = profile.username.isNotEmpty
        ? profile.username
        : _normalizedUsername;
    if (resolvedUserId.isEmpty || resolvedUsername.isEmpty) {
      return;
    }

    _subscribeController.addOrUpdateUser(
      SubscribeModel(
        userId: resolvedUserId,
        username: resolvedUsername,
        isSubscribed: profile.isFollowing,
        followStatus: profile.followStatus,
        subscribedAt: profile.isFollowing ? DateTime.now() : null,
      ),
    );
    _didSeedSubscribeState = true;
  }

  Future<void> _resolveIdentity() async {
    final resolution = await ProfileIdentityService.instance
        .resolveProfileIdentity(widget.profileUserId);

    if (!mounted) {
      return;
    }

    setState(() {
      _identityResolution = resolution;
      _isResolvingIdentity = false;
    });
  }

  String get _normalizedUsername {
    final trimmed = widget.userName.trim();
    if (trimmed.isEmpty) {
      return 'unknown';
    }

    return trimmed.toLowerCase().replaceAll(' ', '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = ref.read(authStateProvider).currentUserId;

    if (currentUserId != _lastLoggedInUserId) {
      _lastLoggedInUserId = currentUserId;
      _isResolvingIdentity = true;
      _resolveIdentity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF42174C),
      body: AnimatedBuilder(
        animation: _profileController.contentListenable,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF42174C), Color(0xFF9544A7)],
              ),
            ),
            child: SafeArea(bottom: false, child: _buildMainContent()),
          );
        },
      ),
    );
  }

  double _dragDistance = 0.0;

  void _selectTab(int index) {
    if (index == _selectedTabNotifier.value || index < 0 || index > 2) return;
    _selectedTabNotifier.value = index;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _handleSwipeLeft() {
    if (_selectedTabNotifier.value < 2) {
      _selectTab(_selectedTabNotifier.value + 1);
    }
  }

  void _handleSwipeRight() {
    if (_selectedTabNotifier.value > 0) {
      _selectTab(_selectedTabNotifier.value - 1);
    }
  }

  Widget _buildMainContent() {
    final loggedInUserId = _lastLoggedInUserId;
    final isDirectOwnProfile =
        loggedInUserId != null &&
        loggedInUserId.isNotEmpty &&
        loggedInUserId.trim() == widget.profileUserId.trim();

    final showSubscribeButton =
        !isDirectOwnProfile &&
        !_isResolvingIdentity &&
        (_identityResolution?.shouldShowSubscribeButton ?? false);
    final showProfileShimmer =
        _profileController.isLoading.value && _profileController.user == null;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Colors.white,
      backgroundColor: AppColors.deepPlum,
      child: showProfileShimmer
          ? const UserProfileShimmer()
          : ValueListenableBuilder<int>(
              valueListenable: _selectedTabNotifier,
              builder: (context, selectedTab, _) {
                return AnimatedBuilder(
                  animation: Listenable.merge([
                    _profileController.contentListenable,
                    _subscribeController,
                  ]),
                  builder: (context, _) {
                    final profile = _profileController.user;
                    final resolvedUserId = (profile?.id.isNotEmpty ?? false)
                        ? profile!.id
                        : widget.profileUserId;
                    final resolvedUsername =
                        (profile?.username.isNotEmpty ?? false)
                        ? profile!.username
                        : _normalizedUsername;
                    final initialIsSubscribed =
                        _subscribeController
                            .getUserSubscribeModel(resolvedUserId)
                            ?.isSubscribed ??
                        profile?.isFollowing ??
                        false;
                    final followStatus = _subscribeController.getFollowStatus(
                      resolvedUserId,
                    );
                    final isPrivate = profile?.isPrivate ?? false;
                    final liveIsFollowing = followStatus == 'following';
                    final canSeeContent =
                        !isPrivate || liveIsFollowing || isDirectOwnProfile;
                    final grid = UserProfileGrid(
                      controller: _profileController,
                      selectedTab: selectedTab,
                      isPrivate: isPrivate,
                      canSeeContent: canSeeContent,
                    );

                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: (_) {
                        _dragDistance = 0.0;
                      },
                      onHorizontalDragUpdate: (details) {
                        _dragDistance += details.delta.dx;
                      },
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0.0;
                        if (velocity < -200 || _dragDistance < -60) {
                          _handleSwipeLeft();
                        } else if (velocity > 200 || _dragDistance > 60) {
                          _handleSwipeRight();
                        }
                        _dragDistance = 0.0;
                      },
                      onHorizontalDragCancel: () {
                        _dragDistance = 0.0;
                      },
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                UserProfileHeader(
                                  displayName:
                                      (profile?.fullName.isNotEmpty ?? false)
                                      ? profile!.fullName
                                      : widget.userName,
                                  username: resolvedUsername,
                                  profileUserId: resolvedUserId,
                                  bio: profile?.bio ?? '',
                                  profileImageUrl:
                                      (profile?.profileImage.isNotEmpty ??
                                          false)
                                      ? profile!.profileImage
                                      : widget.profileImageUrl,
                                  hasActiveStory:
                                      profile?.hasActiveStory ??
                                      widget.initialHasActiveStory,
                                  hasUnseenStory:
                                      profile?.hasUnseenStory ?? false,
                                  hasCloseFriendsStory:
                                      profile?.hasCloseFriendsStory ?? false,
                                  showSubscribeButton: showSubscribeButton,
                                  reserveSubscribeSpace: _isResolvingIdentity,
                                  subscribeController: _subscribeController,
                                  initialIsSubscribed: initialIsSubscribed,
                                  followStatus: followStatus,
                                  action: profile?.action,
                                  isPrivate: isPrivate,
                                  showMessageButton: !isDirectOwnProfile,
                                  onMessageTap: () => _openMessage(
                                    userId: resolvedUserId,
                                    username: resolvedUsername,
                                    profileImage:
                                        (profile?.profileImage.isNotEmpty ??
                                            false)
                                        ? profile!.profileImage
                                        : widget.profileImageUrl,
                                  ),
                                  onFollowRequestHandled: () =>
                                      _profileController.fetchUser(
                                        reason: 'follow_request_responded',
                                        forceRefresh: true,
                                      ),
                                ),
                                SizedBox(height: context.rh(16)),
                                ValueListenableBuilder(
                                  valueListenable:
                                      _profileController.statsNotifier,
                                  builder: (context, stats, child) {
                                    return UserStatsRow(
                                      stats: stats,
                                      onSubscribersTap: () => _openConnections(
                                        userId: resolvedUserId,
                                        initialTab: 0,
                                      ),
                                      onSubscribedTap: () => _openConnections(
                                        userId: resolvedUserId,
                                        initialTab: 1,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: context.rh(14)),
                                ValueListenableBuilder(
                                  valueListenable:
                                      _profileController.highlightList,
                                  builder: (context, highlights, child) {
                                    return UserHighlightsList(
                                      highlights: highlights,
                                      isOwnProfile: false,
                                    );
                                  },
                                ),
                                SizedBox(height: context.rh(7)),
                                UserFilterTabs(
                                  selectedIndex: selectedTab,
                                  onTabSelected: _selectTab,
                                ),
                              ],
                            ),
                          ),
                          ...grid.buildSlivers(context),
                          if (!canSeeContent)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: _PrivateAccountCard(),
                            ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: context.rh(100)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _PrivateAccountCard extends StatelessWidget {
  const _PrivateAccountCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This account is private',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow this account to see their\nposts and gruves.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
