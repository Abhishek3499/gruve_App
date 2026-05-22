import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/profile/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/profile/widgets/profile_grid.dart';
import 'package:gruve_app/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:gruve_app/core/widgets/shimmer/app_shimmer.dart';
import '../data/models/user_profile_model.dart';

import '../widgets/filter_tabs.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_drawer.dart';
import '../widgets/stats_row.dart';
import '../widgets/story_list.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedTab = 0;

  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  /// Own-profile tab stays mounted under [IndexedStack]; listen for logout clears.
  ProfileProvider? _ownProfileProvider;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
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
      _ownProfileProvider = context.read<ProfileProvider>();
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
      await context.read<ProfileProvider>().refreshProfileData(reason: reason);
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
    super.dispose();
  }

  void _onProfileScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;
    const threshold = 360.0;
    if (pos.pixels < pos.maxScrollExtent - threshold) return;

    final provider = context.read<ProfileProvider>();
    if (!provider.canLoadMoreForTab(selectedTab)) return;
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
      // Own profile - use existing ProfileProvider
      final provider = context.watch<ProfileProvider>();

      return Scaffold(
        extendBody: true,
        backgroundColor: const Color(0xFF42174C),
        endDrawer: provider.user != null
            ? ProfileMenuDrawer(profileImage: provider.user?.profileImage)
            : null,
        body: Builder(
          builder: (context) {
            _log(
              '[ProfileScreen] Build state - user: ${provider.user != null}, isLoading: ${provider.isLoading}, error: ${provider.errorMessage}',
            );

            if (provider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
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
            if (provider.user == null) {
              return _buildProfileShimmer();
            }

            return _buildMainContentForOwnProfile(provider);
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
                        const SizedBox(height: 16),
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

  Widget _buildMainContentForOwnProfile(ProfileProvider provider) {
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
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: AnimatedBuilder(
              animation: provider.contentListenable,
              builder: (context, _) {
                final user = provider.user;

                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 130),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7D63D1).withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(100),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 110),
                          StatsRow(
                            subscribersCount: provider.stats.subscribersCount,
                            likesCount: provider.stats.likesCount,
                            videosCount: provider.stats.videosCount,
                          ),
                          const SizedBox(height: 25),
                          StoryList(provider: provider),
                          const SizedBox(height: 20),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ProfileGrid(
                              selectedTab: selectedTab,
                              controller: provider.controller,
                            ),
                          ),
                          SizedBox(height: 100),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 30,
                      left: 0,
                      right: 0,
                      child: ProfileHeader(
                        fullName: (user?.fullName ?? '').trim(),
                        username: () {
                          final username = _displayUsername(user?.username);
                          return username.isEmpty ? '@username' : username;
                        }(),
                        profileImage: user?.profileImage ?? '',
                        hasActiveStory: user?.hasActiveStory ?? false,
                        onProfileUpdated: provider.applyUpdatedProfile,
                      ),
                    ),
                  ],
                );
              },
            ),
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
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 130),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF7D63D1).withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(100),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 110),
                    // Show user stats from UserProfile
                    StatsRow(
                      subscribersCount: userProfile.followersCount,
                      likesCount: userProfile.followingCount,
                      videosCount: userProfile.postsCount,
                    ),
                    const SizedBox(height: 25),
                    // Bio section
                    if (userProfile.bio.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          userProfile.bio,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Follow/Following button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Follow functionality coming soon'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: userProfile.isFollowing
                              ? Colors.grey
                              : const Color(0xFFD42BC2),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        child: Text(
                          userProfile.isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: AppShimmer(
                        child: _buildShimmerGrid(itemCount: 9),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
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
                  onProfileUpdated: null, // Cannot edit other user's profile
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileShimmer() {
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
        child: AppShimmer(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 30),

                const ShimmerCircle(radius: 40),

                const SizedBox(height: 10),

                const ShimmerBox(height: 14, width: 120, borderRadius: 6),

                const SizedBox(height: 6),

                const ShimmerBox(height: 12, width: 80, borderRadius: 6),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (_) {
                    return const Column(
                      children: [
                        ShimmerBox(height: 14, width: 40, borderRadius: 6),
                        SizedBox(height: 6),
                        ShimmerBox(height: 12, width: 30, borderRadius: 6),
                      ],
                    );
                  }),
                ),

                const SizedBox(height: 30),

                _buildShimmerGrid(
                  itemCount: 9,
                  padding: const EdgeInsets.all(10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid({
    required int itemCount,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 13,
      vertical: 20,
    ),
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, _) {
        return const ShimmerBox(
          height: double.infinity,
          width: double.infinity,
          borderRadius: 18,
        );
      },
    );
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
