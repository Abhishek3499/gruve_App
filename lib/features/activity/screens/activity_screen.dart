import 'package:flutter/material.dart';
import '../controllers/activity_controller.dart';
import '../widgets/activity_header.dart';
import '../widgets/activity_summary_section.dart';
import '../widgets/activity_description_section.dart';
import '../widgets/activity_insights_card.dart';
import '../widgets/activity_footer.dart';

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
    debugPrint("[ActivityScreen] Screen initialized");
    _controller = ActivityController();
  }

  @override
  void dispose() {
    debugPrint("[ActivityScreen] Screen disposed");
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
            colors: [Color(0xFF9544A7), Color(0xFF42174C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ActivityHeader(
                onBackPressed: () {
                  debugPrint("[ActivityScreen] Back button tapped");
                  Navigator.of(context).pop();
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 23),
                      ActivitySummarySection(totalTime: _controller.totalTime),
                      const SizedBox(height: 15),
                      ActivityDescriptionSection(
                        description: _controller.description,
                      ),
                      const SizedBox(height: 20),
                      ActivityInsightsCard(controller: _controller),
                      const SizedBox(height: 20),
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
