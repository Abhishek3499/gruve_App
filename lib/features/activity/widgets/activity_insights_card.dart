import 'package:flutter/material.dart';
import '../controllers/activity_controller.dart';
import 'activity_chart_widget.dart';

class ActivityInsightsCard extends StatelessWidget {
  final ActivityController controller;

  const ActivityInsightsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51), // 20% opacity
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Weekly',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ActivityChartWidget(controller: controller),
        ],
      ),
    );
  }
}
