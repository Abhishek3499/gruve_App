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
    _controller = ActivityController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          ActivityHeader(
            onBackPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  ActivitySummarySection(
                    totalTime: _controller.totalTime,
                  ),
                  const SizedBox(height: 20),
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
    );
  }
}
