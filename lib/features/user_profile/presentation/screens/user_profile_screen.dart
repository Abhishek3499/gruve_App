import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/features/user_profile/presentation/controller/user_profile_controller.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/home/presentation/controller/subscribe_controller.dart';
import 'package:gruve_app/features/home/domain/entities/subscribe_model.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/user_filter_tabs.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/user_highlights_list.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/user_profile_grid.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/user_profile_header.dart';
import 'package:gruve_app/features/user_profile/presentation/widgets/user_stats_row.dart';
import 'package:gruve_app/shared/widgets/shimmer/profile_shimmer.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

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
  String? _lastLoggedInUserId;
  int _selectedTab = 0;
  late final UserProfileController _profileController;
  late final SubscribeController _subscribeController;
  bool _didSeedSubscribeState = false;
  bool _isRefreshing = false;
  final ScrollController _scrollController = ScrollController();
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger(
    threshold: 360,
  );

  static Color get _panelBackgroundColor =>
      const Color(0xFF7D63D1).withValues(alpha: 0.12);

  @override
  void initState() {
    super.initState();
    _profileController = UserProfileController(userId: widget.profileUserId);
    _subscribeController = SubscribeController();
    _profileController.contentListenable.addListener(_syncSubscribeState);
    _scrollController.addListener(_onProfileScroll);
    _resolveIdentity();
    _profileController.fetchUser();
  }

  void _onProfileScroll() {
    if (!_scrollController.hasClients) return;

    final tabIndex = _selectedTab == 0 ? 0 : 2;
    if (!_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: _profileController.isLoadingTab(tabIndex),
      hasMore: _profileController.canLoadMoreForTab(tabIndex),
    )) {
      return;
    }

    _profileController.requestLoadMoreThrottled(tabIndex);
  }

  @override
  void dispose() {
    _profileController.contentListenable.removeListener(_syncSubscribeState);
    _scrollController.removeListener(_onProfileScroll);
    _scrollController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _profileController.fetchUser();
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
    final currentUserId = Provider.of<AuthStateManager>(context).currentUserId;

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
    final loggedInUserId = _lastLoggedInUserId;
    final isDirectOwnProfile = loggedInUserId != null &&
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
      backgroundColor: const Color(0xFF42174C),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showProfileShimmer)
            CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildUserProfileShimmer(constraints),
                ),
              ],
            )
          else
            AnimatedBuilder(
              animation: _profileController.contentListenable,
              builder: (context, _) {
                final profile = _profileController.user;
                final resolvedUserId = (profile?.id.isNotEmpty ?? false)
                    ? profile!.id
                    : widget.profileUserId;
                final resolvedUsername = (profile?.username.isNotEmpty ?? false)
                    ? profile!.username
                    : _normalizedUsername;
                final initialIsSubscribed =
                    _subscribeController
                        .getUserSubscribeModel(resolvedUserId)
                        ?.isSubscribed ??
                    profile?.isFollowing ??
                    false;
                final grid = UserProfileGrid(
                  controller: _profileController,
                  selectedTab: _selectedTab,
                );

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
                                topLeft: Radius.circular(110),
                                topRight: Radius.circular(30),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _panelBackgroundColor,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: context.rh(120)),
                                    ValueListenableBuilder(
                                      valueListenable:
                                          _profileController.statsNotifier,
                                      builder: (context, stats, child) {
                                        return UserStatsRow(stats: stats);
                                      },
                                    ),
                                    SizedBox(height: context.rh(20)),
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
                                    SizedBox(height: context.rh(20)),
                                    UserFilterTabs(
                                      selectedIndex: _selectedTab,
                                      onTabSelected: (index) {
                                        setState(() {
                                          _selectedTab = index;
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
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: context.rh(20)),
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
                          ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: context.rw(10)),
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
        ],
      ),
    );
  }

  Widget _buildUserProfileShimmer(BoxConstraints constraints) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: context.rh(130)),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _panelBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(110),
                topRight: Radius.circular(30),
              ),
            ),
            child: SizedBox(height: context.rh(720)),
          ),
        ),
        const UserProfileShimmer(),
      ],
    );
  }
}
