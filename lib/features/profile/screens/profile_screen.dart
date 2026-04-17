import 'package:flutter/material.dart';

import 'package:gruve_app/api_calls/profile/controller/profile_controller.dart';

import 'package:gruve_app/features/profile/widgets/profile_grid.dart';

import '../widgets/filter_tabs.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_drawer.dart';
import '../widgets/stats_row.dart';
import '../widgets/story_list.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedTab = 0;

  final ProfileController controller = ProfileController();

  final ScrollController _scrollController = ScrollController();

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    controller.fetchUser();
    _scrollController.addListener(_onProfileScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onProfileScroll);
    _scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _onProfileScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;
    final threshold = 360.0;
    if (pos.pixels < pos.maxScrollExtent - threshold) return;
    controller.requestLoadMoreThrottled(selectedTab);
  }

  String _displayUsername(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return '';
    return t.startsWith('@') ? t : '@$t';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isLoading,
      builder: (context, loading, _) {
        final showBlockingLoader = loading && !controller.hasLoadedOnce;
        if (showBlockingLoader) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = controller.user;

        return Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFF42174C),
          endDrawer: ProfileMenuDrawer(profileImage: user?.profileImage),
          body: Container(
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
                    animation: controller.contentListenable,
                    builder: (context, _) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 130),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7D63D1)
                                  .withValues(alpha: 0.12),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(100),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 110),
                                StatsRow(
                                  subscribersCount:
                                      controller.stats.subscribersCount,
                                  likesCount: controller.stats.likesCount,
                                  videosCount: controller.stats.videosCount,
                                ),
                                const SizedBox(height: 25),
                                const StoryList(),
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
                                    controller.ensureTabLoaded(index);
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: ProfileGrid(
                                    selectedTab: selectedTab,
                                    controller: controller,
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
                              fullName: (user?.fullName ?? '').trim(),
                              username: () {
                                final u = _displayUsername(user?.username);
                                return u.isEmpty ? '@username' : u;
                              }(),
                              profileImage: user?.profileImage ?? "",
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      await controller.refreshCounts(reason: 'pull_to_refresh');
    } catch (e) {
      debugPrint('❌ Profile pull-to-refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }
}
