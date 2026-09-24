import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/auth/current_user_notifier.dart';

import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:gruve_app/features/profile/presentation/widgets/profile_grid.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_state_notifier.dart';
import 'package:gruve_app/shared/widgets/shimmer/profile_shimmer.dart';

import 'package:share_plus/share_plus.dart';
import 'package:gruve_app/shared/widgets/image_picker_bottom_sheet.dart';
import 'package:gruve_app/features/profile/data/datasource/edit_profile_service.dart';
import 'package:gruve_app/features/profile/data/dto/edit_profile_request.dart';
import 'package:gruve_app/features/connections/presentation/screens/connections_screen.dart';
import 'package:gruve_app/features/profile/presentation/widgets/filter_tabs.dart';
import 'package:gruve_app/features/profile/presentation/widgets/profile_header.dart';
import 'package:gruve_app/features/profile/presentation/widgets/stats_row.dart';
import 'package:gruve_app/features/profile/presentation/widgets/story_list.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int selectedTab = 0;

  final ScrollController _scrollController = ScrollController();
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger(
    threshold: 360,
  );
  bool _isRefreshing = false;

  void _log(String message) {
    AppLogger.d(message);
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
  void initState() {
    super.initState();
    ProfileCountRefreshBridge.onRefreshRequested = _onBridgeRefreshRequested;
    _log('[ProfileScreen] Initializing profile screen');

    // Fetch whenever session has no user yet (fixes stuck loader when init ran
    // while provider falsely reported loading, and refetch after logout).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ensureOwnProfileLoaded(),
    );

    _scrollController.addListener(_onProfileScroll);
  }

  void _ensureOwnProfileLoaded([ProfileState? state]) {
    if (!mounted) return;
    final ProfileState s = state ?? ref.read(profileNotifierProvider);
    if (s.user != null || s.errorMessage != null || s.isLoading) return;
    _log('[ProfileScreen] Fetching profile (empty session, idle)');
    ref.read(profileNotifierProvider.notifier).fetchProfileData();
  }

  Future<void> _onBridgeRefreshRequested(String reason) async {
    if (!mounted) return;
    try {
      final notifier = ref.read(profileNotifierProvider.notifier);
      switch (reason) {
        case 'post_like_toggled':
        case 'subscribe_toggled':
        case 'user_subscribed':
        case 'user_unsubscribed':
          await notifier.refreshCounts(reason: reason);
        default:
          await notifier.refreshProfileData(reason: reason);
      }
    } catch (e, st) {
      _log('[ProfileScreen] Bridge refresh failed: $e\n$st');
    }
  }

  @override
  void dispose() {
    ProfileCountRefreshBridge.onRefreshRequested = null;
    _scrollController.removeListener(_onProfileScroll);
    _scrollController.dispose();
    ref.read(profileNotifierProvider.notifier).cancelActiveRequests();
    super.dispose();
  }

  void _onProfileScroll() {
    if (!_scrollController.hasClients) return;

    final notifier = ref.read(profileNotifierProvider.notifier);
    if (!_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: notifier.controller.isLoadingTab(selectedTab),
      hasMore: notifier.canLoadMoreForTab(selectedTab),
    )) {
      return;
    }

    notifier.requestLoadMoreThrottled(selectedTab);
  }

  String _displayUsername(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '';
    return value.startsWith('@') ? value : '@$value';
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild shell for top-level profile state changes.
    ref.listen<ProfileState>(profileNotifierProvider, (previous, next) {
      _ensureOwnProfileLoaded(next);
    });
    final user = ref.watch(profileNotifierProvider.select((p) => p.user));
    final errorMessage = ref.watch(
      profileNotifierProvider.select((p) => p.errorMessage),
    );
    final hasLocalStory = ref.watch(
      storyStateNotifierProvider.select((s) => s.hasUserStory),
    );
    final hasActiveStory =
        (user?.hasActiveStory ?? false) ||
        (user?.storyCount ?? 0) > 0 ||
        hasLocalStory;
    final hasCloseFriendsStory = user?.hasCloseFriendsStory ?? false;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.deepPlum,
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
                    onPressed: () => ref
                        .read(profileNotifierProvider.notifier)
                        .fetchProfileData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vibrantMagenta,
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
            hasActiveStory: hasActiveStory,
            hasCloseFriendsStory: hasCloseFriendsStory,
          );
        },
      ),
    );
  }

  Future<void> _handleCameraTap() async {
    ImagePickerBottomSheet.show(
      context,
      onImageSelected: (xfile) async {
        try {
          final notifier = ref.read(profileNotifierProvider.notifier);
          final user = notifier.controller.user;
          final response = await EditProfileService().updateProfile(
            request: EditProfileRequest(
              fullname: user?.fullName ?? '',
              username: user?.username ?? '',
              bio: user?.bio,
              profilePicture: xfile.path,
            ),
          );
          notifier.applyUpdatedProfile(response);
          final newImageUrl = response.data.profilePicture;
          final newUsername = response.data.username;
          ref
              .read(currentUserNotifierProvider.notifier)
              .updateProfileData(username: newUsername, imageUrl: newImageUrl);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile photo updated successfully!'),
                backgroundColor: AppColors.vibrantMagenta,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update profile photo: $e'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      },
    );
  }

  void _handleShareProfile({
    required String username,
    required String fullName,
  }) {
    final cleanUsername = username.replaceAll('@', '').trim();
    final shareText =
        'Check out $fullName (@$cleanUsername) on Gruve!\nhttps://gruve.app/user/$cleanUsername';
    SharePlus.instance.share(
      ShareParams(text: shareText, subject: '$fullName on Gruve'),
    );
  }

  Widget _buildMainContentForOwnProfile({
    required bool hasActiveStory,
    required bool hasCloseFriendsStory,
  }) {
    final notifier = ref.read(profileNotifierProvider.notifier);
    final controller = notifier.controller;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.deepPlum, Color(0xFF212235)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.white,
          backgroundColor: AppColors.deepPlum,
          child: AnimatedBuilder(
            animation: controller.contentListenable,
            builder: (context, _) {
              final grid = ProfileGrid(
                selectedTab: selectedTab,
                controller: controller,
              );
              final user = controller.user;

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        ProfileHeader(
                          fullName: (user?.fullName ?? '').trim(),
                          username: () {
                            final username = _displayUsername(user?.username);
                            return username.isEmpty ? '@username' : username;
                          }(),
                          bio: user?.bio ?? '',
                          profileImage: user?.profileImage ?? '',
                          hasActiveStory: hasActiveStory,
                          hasCloseFriendsStory: hasCloseFriendsStory,
                          onAvatarCameraTap: _handleCameraTap,
                          onShareProfileTap: () => _handleShareProfile(
                            username: user?.username ?? '',
                            fullName: user?.fullName ?? '',
                          ),
                          onProfileUpdated: (response) {
                            notifier.applyUpdatedProfile(response);
                            final newImageUrl = response.data.profilePicture;
                            final newUsername = response.data.username;
                            ref
                                .read(currentUserNotifierProvider.notifier)
                                .updateProfileData(
                                  username: newUsername,
                                  imageUrl: newImageUrl,
                                );
                          },
                        ),
                        SizedBox(height: context.rh(22)),
                        StatsRow(
                          subscribersCount: controller.stats.subscribersCount,
                          likesCount: controller.stats.likesCount,
                          videosCount: controller.stats.videosCount,
                          onSubscribersTap: () => _openConnections(
                            userId: user?.id ?? '',
                            initialTab: 0,
                          ),
                          onSubscribedTap: () => _openConnections(
                            userId: user?.id ?? '',
                            initialTab: 1,
                          ),
                        ),
                        SizedBox(height: context.rh(25)),
                        const StoryList(),
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
                            notifier.ensureTabLoaded(index);
                          },
                        ),
                      ],
                    ),
                  ),
                  ...grid.buildSlivers(context),
                  SliverToBoxAdapter(child: SizedBox(height: context.rh(100))),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileShimmer() {
    return const ProfileShimmer();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .refreshProfileData(reason: 'pull_to_refresh');
    } catch (e) {
      _log('[ProfileScreen] Pull-to-refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }
}
