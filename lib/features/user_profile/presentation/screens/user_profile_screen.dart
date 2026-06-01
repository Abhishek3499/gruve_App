import 'package:flutter/material.dart';
import 'package:gruve_app/features/user_profile/data/controller/user_profile_controller.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/home/controllers/subscribe_controller.dart';
import 'package:gruve_app/features/home/models/subscribe_model.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_filter_tabs.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_highlights_list.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_profile_grid.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_profile_header.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_stats_row.dart';
import 'package:gruve_app/core/widgets/shimmer/app_shimmer.dart';

class UserProfileScreen extends StatefulWidget {
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
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  ProfileIdentityResolution? _identityResolution;
  bool _isResolvingIdentity = true;
  int _selectedTab = 0;
  late final UserProfileController _profileController;
  late final SubscribeController _subscribeController;
  bool _didSeedSubscribeState = false;
  bool _isRefreshing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _profileController = UserProfileController(userId: widget.profileUserId);
    _subscribeController = SubscribeController();
    _profileController.contentListenable.addListener(_syncSubscribeState);
    _resolveIdentity();
    _profileController.fetchUser();
  }

  @override
  void dispose() {
    _profileController.contentListenable.removeListener(_syncSubscribeState);
    _profileController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _profileController.fetchUser();
      debugPrint(
        '✅ [UserProfileScreen] Pull-to-refresh completed successfully',
      );
    } catch (e) {
      debugPrint('❌ [UserProfileScreen] Pull-to-refresh failed: $e');
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      /// 🔹 MAIN UI (always show, skeletons handle loading internally)
                      _buildMainContent(constraints),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(BoxConstraints constraints) {
    final showSubscribeButton =
        !_isResolvingIdentity &&
        (_identityResolution?.shouldShowSubscribeButton ?? false);
    final showProfileShimmer =
        _profileController.isLoading.value || _isRefreshing;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Colors.white,
      backgroundColor: const Color(0xFF42174C),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Stack(
            children: [
              if (showProfileShimmer)
                _buildUserProfileShimmer(constraints)
              else ...[
                Padding(
                  padding: const EdgeInsets.only(top: 130),
                  child: Stack(
                    children: [
                      _buildProfilePanelBackground(constraints),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 120),
                          ValueListenableBuilder(
                            valueListenable: _profileController.statsNotifier,
                            builder: (context, stats, child) {
                              return UserStatsRow(stats: stats);
                            },
                          ),
                          const SizedBox(height: 20),
                          ValueListenableBuilder(
                            valueListenable: _profileController.highlightList,
                            builder: (context, highlights, child) {
                              debugPrint(
                                '[UserProfileScreen] Highlights count: ${highlights.length}',
                              );
                              return UserHighlightsList(
                                highlights: highlights,
                                isOwnProfile: false,
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          UserFilterTabs(
                            selectedIndex: _selectedTab,
                            onTabSelected: (index) {
                              setState(() {
                                _selectedTab = index;
                              });
                            },
                          ),
                          UserProfileGrid(
                            controller: _profileController,
                            selectedTab: _selectedTab,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _profileController.contentListenable,
                  builder: (context, child) {
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

                    return Column(
                      children: [
                        const SizedBox(height: 20),
                        UserProfileHeader(
                          displayName: widget.userName,
                          username: resolvedUsername,
                          profileUserId: resolvedUserId,
                          profileImageUrl:
                              (profile?.profileImage.isNotEmpty ?? false)
                              ? profile!.profileImage
                              : widget.profileImageUrl,
                          hasActiveStory:
                              profile?.hasActiveStory ??
                              widget.initialHasActiveStory,
                          showSubscribeButton: showSubscribeButton,
                          reserveSubscribeSpace: _isResolvingIdentity,
                          subscribeController: _subscribeController,
                          initialIsSubscribed: initialIsSubscribed,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePanelBackground(BoxConstraints constraints) {
    return Container(
      height: constraints.maxHeight,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.only(top: 250, bottom: 120),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x267D63D1), Color(0x26212235)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(110),
          topRight: Radius.circular(30),
          bottomLeft: Radius.circular(80),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7D63D1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileShimmer(BoxConstraints constraints) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 130),
          child: _buildProfilePanelBackground(constraints),
        ),
        AppShimmer(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 120),
                    _buildStatsShimmer(),
                    const SizedBox(height: 20),
                    _buildStoriesShimmer(),
                    const SizedBox(height: 20),
                    _buildUserTabsShimmer(),
                    _buildGridShimmer(itemCount: 9),
                  ],
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 20),
                  _buildUserHeaderShimmer(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeaderShimmer() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: const [
              ShimmerBox(width: 44, height: 44, borderRadius: 22),
              Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerCircle(radius: 50),
              SizedBox(width: 25),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    ShimmerBox(width: 145, height: 22, borderRadius: 8),
                    SizedBox(height: 8),
                    ShimmerBox(width: 105, height: 16, borderRadius: 8),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        ShimmerBox(width: 132, height: 42, borderRadius: 30),
                        SizedBox(width: 21),
                        ShimmerCircle(radius: 21),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatShimmer(width: 78),
          _buildDividerShimmer(),
          _buildStatShimmer(width: 40),
          _buildDividerShimmer(),
          _buildStatShimmer(width: 48),
        ],
      ),
    );
  }

  Widget _buildStatShimmer({required double width}) {
    return Column(
      children: [
        const ShimmerBox(width: 42, height: 22, borderRadius: 8),
        const SizedBox(height: 6),
        ShimmerBox(width: width, height: 14, borderRadius: 8),
      ],
    );
  }

  Widget _buildDividerShimmer() {
    return Container(height: 40, width: 1.2, color: Colors.white);
  }

  Widget _buildStoriesShimmer() {
    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 30, right: 12),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerCircle(radius: 32),
                SizedBox(height: 6),
                ShimmerBox(width: 58, height: 12, borderRadius: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserTabsShimmer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        ShimmerBox(width: 94, height: 40, borderRadius: 30),
        SizedBox(width: 20),
        ShimmerBox(width: 78, height: 40, borderRadius: 30),
      ],
    );
  }

  Widget _buildGridShimmer({required int itemCount}) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        return const ShimmerBox(
          width: double.infinity,
          height: double.infinity,
          borderRadius: 18,
        );
      },
    );
  }
}
