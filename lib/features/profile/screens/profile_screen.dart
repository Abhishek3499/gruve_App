import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/profile_header.dart';
import '../widgets/stats_row.dart';
import '../widgets/story_list.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/profile_grid.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9544A7),
      body: Container(
        // decoration: const BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topCenter,
        //     end: Alignment.bottomCenter,
        //     colors: [
        //       AppColors.profileGradientTop,
        //       AppColors.profileGradientBottom,
        //     ],
        //   ),
        // ),
        child: SafeArea(
          child: Stack(
            children: [
              /// 🔥 CURVE BACKGROUND FULL HEIGHT
              Positioned.fill(
                top: 120, // adjust for overlap
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7D63D1), Color(0xFF212235)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      topRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),

              /// 🔥 FULL CONTENT SCROLL
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    const ProfileHeader(),

                    const SizedBox(height: 25),

                    const StatsRow(),

                    const SizedBox(height: 25),

                    const StoryList(),

                    const SizedBox(height: 30),

                    /// 👇 Tabs now ABOVE curve visually
                    const FilterTabs(),

                    const SizedBox(height: 25),

                    /// 👇 GRID PROPERLY VISIBLE (NO BLACK GAP)
                    const ProfileGrid(),

                    const SizedBox(height: 120), // spacing for bottom nav
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
