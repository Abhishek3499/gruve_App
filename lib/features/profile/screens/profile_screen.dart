import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/profile/Controller/profile_controller.dart';
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

  @override
  void initState() {
    super.initState();
    controller.fetchUser();
  }

  @override
  void dispose() {
    controller.isLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isLoading,
      builder: (context, isLoading, child) {
        if (isLoading) {
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
              child: SingleChildScrollView(
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
                          StatsRow(
                            subscribersCount: controller.stats?.subscribersCount ?? 0,
                            likesCount: controller.stats?.likesCount ?? 0,
                            videosCount: controller.stats?.videosCount ?? 0,
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
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ProfileGrid(selectedTab: selectedTab),
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
                        fullName: user?.fullName ?? "",
                        username: user?.username ?? "@username",
                        profileImage: user?.profileImage ?? "",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
