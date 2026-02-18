import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/data/models/user_model.dart';
import 'package:gruve_app/features/profile/data/dummy_users.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/profile_header.dart';
import '../widgets/stats_row.dart';
import '../widgets/story_list.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/profile_grid.dart';
import '../widgets/profile_menu_drawer.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Always use current user for MyProfileScreen
    final user = DummyUsers.getCurrentUser();

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.profileGradientBottom,
      endDrawer: ProfileMenuDrawer(user: user),
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
                      /// BODY CONTENT
                      Padding(
                        padding: const EdgeInsets.only(top: 130),
                        child: Stack(
                          children: [
                            /// CURVED CONTAINER (Full Height)
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
                                    Color(0xFF7D63D1),
                                    Color(0xFF212235),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(110),
                                  topRight: Radius.circular(30),
                                  bottomLeft: Radius.circular(80),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7D63D1).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                            ),

                            /// CONTENT ABOVE CURVE
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 120),
                                StatsRow(user: user),
                                const SizedBox(height: 20),
                                StoryList(user: user),
                                const SizedBox(height: 20),
                                FilterTabs(),
                                const SizedBox(height: 15),
                                ProfileGrid(user: user),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /// HEADER
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          ProfileHeader(user: user),
                        ],
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
