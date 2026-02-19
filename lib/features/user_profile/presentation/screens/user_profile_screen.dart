import 'package:flutter/material.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_filter_tabs.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_profile_grid.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_profile_header.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_stats_row.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/user_story_list.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // backgroundColor: AppColors.profileGradientBottom,
      // endDrawer: const ProfileMenuDrawer(),
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
                      /// 🔥 BODY CONTENT
                      Padding(
                        padding: const EdgeInsets.only(top: 130),
                        child: Stack(
                          children: [
                            /// 🔥 CURVED CONTAINER
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 120),
                                UserStatsRow(),
                                SizedBox(height: 20),
                                UserStoryList(),
                                SizedBox(height: 20),
                                UserFilterTabs(),
                                UserProfileGrid(),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /// 🔥 HEADER
                      const Column(
                        children: [SizedBox(height: 20), UserProfileHeader()],
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
