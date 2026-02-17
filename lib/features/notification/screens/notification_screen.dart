import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import '../widgets/header.dart';
import '../widgets/section_title.dart';
import '../widgets/today_section.dart';
import '../widgets/new_section.dart';
import '../widgets/this_week_section.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bottomBlack,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientTop, AppColors.gradientBottom],
          ),
        ),
        child: const SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),

                Header(),

                SizedBox(height: 24),

                TodaySection(),

                NewSection(),

                SizedBox(height: 20),

                SectionTitle(title: "This Week"),
                ThisWeekSection(),

                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
