import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/user_profile/data/controller/user_profile_controller.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/home/controllers/subscribe_controller.dart';
import 'package:gruve_app/features/home/models/subscribe_model.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_filter_tabs.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_highlights_list.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_profile_grid.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_profile_header.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_stats_row.dart';
import 'package:gruve_app/core/widgets/shimmer/profile_shimmer.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
                              AppLogger.d(
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
        const UserProfileShimmer(),
      ],
    );
  }
}
