import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/user_profile/controller/user_profile_controller.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/home/controllers/subscribe_controller.dart';
import 'package:gruve_app/features/home/models/subscribe_model.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_filter_tabs.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_profile_grid.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_profile_header.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_stats_row.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_story_list.dart';

class UserProfileScreen extends StatefulWidget {
  final String profileUserId;
  final String userName;
  final String? profileImageUrl;

  const UserProfileScreen({
    super.key,
    required this.profileUserId,
    required this.userName,
    this.profileImageUrl,
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
    super.dispose();
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
    final showSubscribeButton =
        !_isResolvingIdentity &&
        (_identityResolution?.shouldShowSubscribeButton ?? false);

    return Scaffold(
      extendBody: true,
      body: Container(
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
              return SingleChildScrollView(
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
                              padding: const EdgeInsets.only(
                                top: 250,
                                bottom: 120,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x267D63D1),
                                    Color(0x26212235),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(110),
                                  topRight: Radius.circular(30),
                                  bottomLeft: Radius.circular(80),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF7D63D1,
                                    ).withValues(alpha: 0.3),
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
                                UserStoryList(),
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
                          final resolvedUserId =
                              (profile?.id.isNotEmpty ?? false)
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
                                profileImageUrl: widget.profileImageUrl,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
