import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/widgets/profile_grid.dart';

import '../widgets/profile_header.dart';
import '../widgets/stats_row.dart';
import '../widgets/story_list.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/profile_menu_drawer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // Background color base
      backgroundColor: const Color(0xFF42174C),
      endDrawer: const ProfileMenuDrawer(),
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
                /// 1. 🔥 CURVED BACKGROUND CONTAINER
                /// Iska margin-top header ke center tak rakha hai taaki avatar overlap kare
                Container(
                  margin: const EdgeInsets.only(top: 130),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    // Glassy purple effect as seen in SS
                    color: const Color(0xFF7D63D1).withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(100),
                      topRight: Radius.circular(30),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header aur Stats ke beech ka space adjust kiya
                      const SizedBox(height: 110),

                      const StatsRow(),

                      const SizedBox(height: 25),

                      const StoryList(),

                      const SizedBox(height: 20),

                      const FilterTabs(),

                      // Grid thoda padding ke sath taaki curve se na chipke
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: ProfileGrid(),
                      ),

                      const SizedBox(height: 100), // Bottom spacing
                    ],
                  ),
                ),

                /// 2. 🔥 PROFILE HEADER (Avatar, Name, Edit Profile)
                /// Isko Positioned rakha hai taaki ye top center mein fix rahe
                const Positioned(
                  top: 30,
                  left: 0,
                  right: 0,
                  child: ProfileHeader(),
                ),

                /// 3. 🔥 DRAWER / MENU BUTTON
                // Positioned(
                //   top: 10,
                //   right: 15,
                //   child: Builder(
                //     builder: (context) => IconButton(
                //       icon: const Icon(
                //         Icons.menu,
                //         color: Colors.white,
                //         size: 28,
                //       ),
                //       onPressed: () => Scaffold.of(context).openEndDrawer(),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
