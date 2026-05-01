import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/user_profile/controller/user_profile_controller.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/home/controllers/subscribe_controller.dart';
import 'package:gruve_app/features/home/models/subscribe_model.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_filter_tabs.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_highlights_list.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_profile_grid.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_profile_header.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_stats_row.dart';

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

    _isRefreshing = true;

    try {
      await _profileController.fetchUser();
      debugPrint('✅ [UserProfileScreen] Pull-to-refresh completed successfully');
    } catch (e) {
      debugPrint('❌ [UserProfileScreen] Pull-to-refresh failed: $e');
    } finally {
      _isRefreshing = false;
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
                      /// 🔹 MAIN UI (only if data exists)
                      if (_profileController.user != null)
                        _buildMainContent(constraints),

                      /// 🔹 SKELETON (first load only)
                      if (_profileController.user == null)
                        _buildSkeleton(constraints),
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
            Padding(
              padding: const EdgeInsets.only(top: 130),
              child: Stack(
                children: [
                  Container(
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
                  ),
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
                      // User highlights from API (data['data']['highlights'])
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
                      AnimatedBuilder(
                        animation: _profileController.contentListenable,
                        builder: (context, child) {
                          return UserProfileGrid(
                            controller: _profileController,
                            selectedTab: _selectedTab,
                          );
                        },
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
                final resolvedUsername = (profile?.username.isNotEmpty ?? false)
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
        ),
      ),
      ),
    );
  }

  Widget _buildSkeleton(BoxConstraints constraints) {
    return SizedBox(
      height: constraints.maxHeight,
      width: double.infinity,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              /// Profile image
              const CircleAvatar(radius: 40, backgroundColor: Colors.white12),

              const SizedBox(height: 10),

              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),

              const SizedBox(height: 6),

              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),

              const SizedBox(height: 30),

              /// Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (_) {
                  return Column(
                    children: [
                      Container(
                        height: 14,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 30),

              /// Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (_, _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
