import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/auth/current_user_provider.dart';

import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_provider.dart';
import 'package:gruve_app/features/profile/presentation/widgets/profile_grid.dart';
import 'package:gruve_app/features/profile/presentation/controller/user_profile_provider.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/story_state_controller.dart';
import 'package:gruve_app/shared/widgets/shimmer/profile_shimmer.dart';
import 'package:gruve_app/features/profile/domain/entities/user_profile_model.dart';

import 'package:gruve_app/features/profile/presentation/widgets/filter_tabs.dart';
import 'package:gruve_app/features/profile/presentation/widgets/profile_header.dart';
import 'package:gruve_app/features/profile/presentation/widgets/stats_row.dart';
import 'package:gruve_app/features/profile/presentation/widgets/story_list.dart';
import 'package:gruve_app/shared/widgets/post_grid_thumbnail.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedTab = 0;

  static Color get _panelBackgroundColor =>
      const Color(0xFF7D63D1).withValues(alpha: 0.12);

  final ScrollController _scrollController = ScrollController();
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger(
    threshold: 360,
  );
  bool _isRefreshing = false;

  /// Own-profile tab stays mounted under [IndexedStack]; listen for logout clears.
  ProfileProvider? _ownProfileProvider;
  UserProfileProvider? _userProfileProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.userId == null) {
      _ownProfileProvider ??= context.read<ProfileProvider>();
    } else {
      _userProfileProvider ??= context.read<UserProfileProvider>();
    }
  }

  void _log(String message) {
    AppLogger.d(message);
  }

  @override
  void initState() {
    super.initState();
    ProfileCountRefreshBridge.onRefreshRequested = _onBridgeRefreshRequested;
    _log(
      '[ProfileScreen] Initializing profile screen with userId: ${widget.userId}',
    );

    // Own profile: fetch whenever session has no user yet (fixes stuck loader when
    // init ran while provider falsely reported loading, and refetch after logout).
    if (widget.userId == null) {
      _ownProfileProvider ??= context.read<ProfileProvider>();
      _ownProfileProvider!.addListener(_ensureOwnProfileLoaded);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureOwnProfileLoaded(),
      );
    } else {
      // Other user's profile - fetch using UserProfileProvider after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<UserProfileProvider>().fetchProfile(widget.userId!);
        }
      });
    }

    _scrollController.addListener(_onProfileScroll);
  }

  void _ensureOwnProfileLoaded() {
    if (!mounted || widget.userId != null) return;
    final p = _ownProfileProvider ?? context.read<ProfileProvider>();
    if (p.user != null || p.errorMessage != null || p.isLoading) return;
    _log('[ProfileScreen] Fetching profile (empty session, idle)');
    p.fetchProfileData();
  }

  Future<void> _onBridgeRefreshRequested(String reason) async {
    if (!mounted) return;
    try {
      final provider = context.read<ProfileProvider>();
      switch (reason) {
        case 'post_like_toggled':
        case 'subscribe_toggled':
        case 'user_subscribed':
        case 'user_unsubscribed':
          await provider.refreshCounts(reason: reason);
        default:
          await provider.refreshProfileData(reason: reason);
      }
    } catch (e, st) {
      _log('[ProfileScreen] Bridge refresh failed: $e\n$st');
    }
  }

  @override
  void dispose() {
    _ownProfileProvider?.removeListener(_ensureOwnProfileLoaded);
    ProfileCountRefreshBridge.onRefreshRequested = null;
    _scrollController.removeListener(_onProfileScroll);
    _scrollController.dispose();
    if (widget.userId == null) {
      _ownProfileProvider?.cancelActiveRequests();
    } else {
      _userProfileProvider?.cancelActiveRequests();
    }
    super.dispose();
  }

  void _onProfileScroll() {
    if (!_scrollController.hasClients) return;

    final provider = context.read<ProfileProvider>();
    if (!_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: provider.controller.isLoadingTab(selectedTab),
      hasMore: provider.canLoadMoreForTab(selectedTab),
    )) {
      return;
    }

    provider.requestLoadMoreThrottled(selectedTab);
  }

  String _displayUsername(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '';
    return value.startsWith('@') ? value : '@$value';
  }

  @override
  Widget build(BuildContext context) {
    // Handle both own profile and other users
    if (widget.userId == null) {
      // Own profile - only rebuild shell for top-level profile state changes.
      final provider = context.read<ProfileProvider>();
      final user = context.select((ProfileProvider p) => p.user);
      final errorMessage = context.select(
        (ProfileProvider p) => p.errorMessage,
      );
      final hasLocalStory = context.select(
        (StoryStateController s) => s.hasUserStory,
      );
      final hasActiveStory =
          (user?.hasActiveStory ?? false) ||
          (user?.storyCount ?? 0) > 0 ||
          hasLocalStory;

      return Scaffold(
        extendBody: true,
        backgroundColor: const Color(0xFF42174C),
        body: Builder(
          builder: (context) {
            if (errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.rh(16)),
                    ElevatedButton(
                      onPressed: () => provider.fetchProfileData(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD42BC2),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Show shimmer immediately when user is null (logout or initial load)
            if (user == null) {
              return _buildProfileShimmer();
            }

            return _buildMainContentForOwnProfile(
              provider,
              hasActiveStory: hasActiveStory,
            );
          },
        ),
      );
    } else {
      // Other user's profile - use UserProfileProvider
      return Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
          return Scaffold(
            extendBody: true,
            backgroundColor: const Color(0xFF42174C),
            body: Builder(
              builder: (context) {
                if (userProfileProvider.isLoading) {
                  return _buildProfileShimmer();
                }

                if (userProfileProvider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userProfileProvider.errorMessage ??
                              'Failed to load profile',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.rh(16)),
                        ElevatedButton(
                          onPressed: () {
                            userProfileProvider.fetchProfile(widget.userId!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD42BC2),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (userProfileProvider.hasData) {
                  return _buildMainContentForOtherUser(
                    userProfileProvider.profile!,
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          );
        },
      );
    }
  }

  Widget _buildMainContentForOwnProfile(
    ProfileProvider provider, {
    required bool hasActiveStory,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF42174C), Color(0xFF212235)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.white,
          backgroundColor: const Color(0xFF42174C),
          child: AnimatedBuilder(
            animation: provider.contentListenable,
            builder: (context, _) {
              final grid = ProfileGrid(
                selectedTab: selectedTab,
                controller: provider.controller,
              );
              final user = provider.user;

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: context.rh(130)),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(100),
                              topRight: Radius.circular(30),
                            ),
                            child: ColoredBox(
                              color: _panelBackgroundColor,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: context.rh(110)),
                                  StatsRow(
                                    subscribersCount:
                                        provider.stats.subscribersCount,
                                    likesCount: provider.stats.likesCount,
                                    videosCount: provider.stats.videosCount,
                                  ),
                                  SizedBox(height: context.rh(25)),
                                  StoryList(provider: provider),
                                  SizedBox(height: context.rh(20)),
                                  FilterTabs(
                                    selectedIndex: selectedTab,
                                    onTabSelected: (index) {
                                      setState(() {
                                        selectedTab = index;
                                      });
                                      if (_scrollController.hasClients) {
                                        _scrollController.jumpTo(0);
                                      }
                                      provider.ensureTabLoaded(index);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 30,
                          left: 0,
                          right: 0,
                          child: ProfileHeader(
                            fullName: (user?.fullName ?? '').trim(),
                            username: () {
                              final username =
                                  _displayUsername(user?.username);
                              return username.isEmpty
                                  ? '@username'
                                  : username;
                            }(),
                            profileImage: user?.profileImage ?? '',
                            hasActiveStory: hasActiveStory,
                            onProfileUpdated: (response) {
                              provider.applyUpdatedProfile(response);
                              final newImageUrl =
                                  response.data.profilePicture;
                              final newUsername = response.data.username;
                              context
                                  .read<CurrentUserProvider>()
                                  .updateProfileData(
                                    username: newUsername,
                                    imageUrl: newImageUrl,
                                  );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.rw(10),
                    ),
                    sliver: DecoratedSliver(
                      decoration: BoxDecoration(color: _panelBackgroundColor),
                      sliver: SliverMainAxisGroup(
                        slivers: grid.buildSlivers(context),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ColoredBox(
                      color: _panelBackgroundColor,
                      child: SizedBox(height: context.rh(100)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainContentForOtherUser(UserProfile userProfile) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF42174C), Color(0xFF212235)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: context.rh(130)),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(100),
                        topRight: Radius.circular(30),
                      ),
                      child: ColoredBox(
                        color: _panelBackgroundColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: context.rh(110)),
                            StatsRow(
                              subscribersCount: userProfile.followersCount,
                              likesCount: userProfile.followingCount,
                              videosCount: userProfile.postsCount,
                            ),
                            SizedBox(height: context.rh(25)),
                            if (userProfile.bio.isNotEmpty) ...[
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.rw(20),
                                ),
                                child: Text(
                                  userProfile.bio,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.rf(14),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: context.rh(20)),
                            ],
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.rw(20),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Follow functionality coming soon',
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: userProfile.isFollowing
                                      ? Colors.grey
                                      : const Color(0xFFD42BC2),
                                  minimumSize:
                                      const Size(double.infinity, 45),
                                ),
                                child: Text(
                                  userProfile.isFollowing
                                      ? 'Following'
                                      : 'Follow',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.rf(16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: context.rh(20)),
                            FilterTabs(
                              selectedIndex: selectedTab,
                              onTabSelected: (index) {
                                setState(() {
                                  selectedTab = index;
                                });
                                if (_scrollController.hasClients) {
                                  _scrollController.jumpTo(0);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 0,
                    right: 0,
                    child: ProfileHeader(
                      fullName: userProfile.fullName.trim(),
                      username: _displayUsername(userProfile.username),
                      profileImage: userProfile.profilePicture,
                      hasActiveStory: false,
                      onProfileUpdated: null,
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: context.rw(10)),
              sliver: DecoratedSliver(
                decoration: BoxDecoration(color: _panelBackgroundColor),
                sliver: SliverMainAxisGroup(
                  slivers: _buildOtherUserGridSlivers(userProfile),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ColoredBox(
                color: _panelBackgroundColor,
                child: SizedBox(height: context.rh(100)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileShimmer() {
    return const ProfileShimmer();
  }

  List<Widget> _buildOtherUserGridSlivers(UserProfile userProfile) {
    final posts = selectedTab == 2
        ? userProfile.likedPosts
        : userProfile.allPosts;

    if (posts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(
              horizontal: context.rw(13),
              vertical: context.rh(20),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.rw(24),
              vertical: context.rh(36),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  color: Colors.white,
                  size: context.rw(34),
                ),
                SizedBox(height: context.rh(12)),
                Text(
                  'No posts yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.rf(18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: ProfileGrid.gridPadding,
        sliver: SliverGrid(
          gridDelegate: ProfileGrid.gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = posts[index];
              final media = (post.thumbnailUrl?.trim().isNotEmpty == true)
                  ? post.thumbnailUrl!.trim()
                  : post.mediaUrl.trim();

              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: media.isEmpty
                    ? Container(
                        color: Colors.white.withValues(alpha: 0.10),
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                        ),
                      )
                    : MediaUrlThumbnail(
                        url: media,
                        memCacheWidth: 300,
                        memCacheHeight: 400,
                      ),
              );
            },
            childCount: posts.length,
          ),
        ),
      ),
    ];
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      await context.read<ProfileProvider>().refreshProfileData(
        reason: 'pull_to_refresh',
      );
    } catch (e) {
      _log('[ProfileScreen] Pull-to-refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }
}
