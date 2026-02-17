import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import '../widgets/search_bar.dart';
import '../widgets/profile_section.dart';
import '../widgets/horizontal_image_list.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF42174C), Color(0xFF9544A7)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),

                /// SEARCH BAR
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CustomSearchBar(),
                ),

                const SizedBox(height: 20),

                /// BANNER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppAssets.baner,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// FIRST PROFILE
                ProfileSection(
                  username: "MindChargedBody",
                  subtitle: "Challenge",
                  stats: "1.5 B",
                  profileImage: AppAssets.profile,
                ),

                const SizedBox(height: 16),

                HorizontalImageList(
                  imageList: [
                    AppAssets.frame1,
                    AppAssets.frame2,
                    AppAssets.frame3,
                  ],
                ),

                const SizedBox(height: 24),

                /// SECOND PROFILE
                ProfileSection(
                  username: "Fitnessguru",
                  subtitle: "Challenge",
                  stats: "2.3 B",
                  profileImage: AppAssets.profile,
                ),

                const SizedBox(height: 16),

                HorizontalImageList(
                  imageList: [
                    AppAssets.frame1,
                    AppAssets.frame1,
                    AppAssets.frame3,
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
