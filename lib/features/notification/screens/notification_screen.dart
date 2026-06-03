import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import '../widgets/header.dart';
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Header(),
                    TodaySection(),
                    NewSection(),
                    ThisWeekSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
