import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/widgets/profile_grid.dart';
import '../../../core/constants/app_colors.dart';
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
      extendBody: true, // 🔥 Important
      backgroundColor: AppColors.profileGradientBottom,
      endDrawer: const ProfileMenuDrawer(),
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
          bottom: false, // 🔥 Remove bottom safe padding
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Stack(
                    children: [
                      /// 🔥 BODY CONTENT
                      Padding(
                        padding: const EdgeInsets.only(top: 130),
                        child: Stack(
                          children: [
                            /// 🔥 CURVED CONTAINER (Full Height)
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

                            /// 🔥 CONTENT ABOVE CURVE
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 120),
                                StatsRow(),
                                SizedBox(height: 20),
                                StoryList(),
                                SizedBox(height: 20),
                                FilterTabs(),

                                ProfileGrid(),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /// 🔥 HEADER
                      const Column(
                        children: [SizedBox(height: 20), ProfileHeader()],
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
