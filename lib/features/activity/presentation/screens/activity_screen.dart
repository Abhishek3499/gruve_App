import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/activity/presentation/controller/activity_controller.dart';
import 'package:gruve_app/features/activity/presentation/widgets/activity_header.dart';
import 'package:gruve_app/features/activity/presentation/widgets/activity_summary_section.dart';
import 'package:gruve_app/features/activity/presentation/widgets/activity_description_section.dart';
import 'package:gruve_app/features/activity/presentation/widgets/activity_insights_card.dart';
import 'package:gruve_app/features/activity/presentation/widgets/activity_footer.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late final ActivityController _controller;

  @override
  void initState() {
    super.initState();
    AppLogger.d("[ActivityScreen] Screen initialized");
    _controller = ActivityController();
  }

  @override
  void dispose() {
    AppLogger.d("[ActivityScreen] Screen disposed");
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF431047), Color(0xFF050006)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ActivityHeader(
                onBackPressed: () {
                  AppLogger.d("[ActivityScreen] Back button tapped");
                  Navigator.of(context).pop();
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: context.rh(27)),
                      ActivitySummarySection(totalTime: _controller.totalTime),
                      SizedBox(height: context.rh(28)),
                      ActivityDescriptionSection(
                        description: _controller.description,
                      ),
                      SizedBox(height: context.rh(34)),
                      ActivityInsightsCard(controller: _controller),
                      SizedBox(height: context.rh(20)),
                      const ActivityFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
