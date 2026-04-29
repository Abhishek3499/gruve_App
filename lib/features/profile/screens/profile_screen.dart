import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/profile/widgets/profile_grid.dart';
import 'package:provider/provider.dart';

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

  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    ProfileCountRefreshBridge.onRefreshRequested = _onBridgeRefreshRequested;
    debugPrint('[ProfileScreen] Initializing profile screen');
    context.read<ProfileProvider>().fetchProfileData();
    _scrollController.addListener(_onProfileScroll);
  }

  Future<void> _onBridgeRefreshRequested(String reason) async {
    if (!mounted) return;
    try {
      await context.read<ProfileProvider>().refreshProfileData(reason: reason);
    } catch (e, st) {
      debugPrint('[ProfileScreen] Bridge refresh failed: $e\n$st');
    }
  }

  @override
  void dispose() {
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
    final provider = context.watch<ProfileProvider>();

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            provider.errorMessage!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF42174C),
      endDrawer: ProfileMenuDrawer(profileImage: provider.user?.profileImage),
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
                animation: provider.contentListenable,
                builder: (context, _) {
                  final user = provider.user;
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 130),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF7D63D1,
                          ).withValues(alpha: 0.12),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: ProfileGrid(
                                selectedTab: selectedTab,
                                controller: provider.controller,
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
      ),
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
      debugPrint('[ProfileScreen] Pull-to-refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }
}
