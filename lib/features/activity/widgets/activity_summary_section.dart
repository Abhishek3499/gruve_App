import 'package:flutter/material.dart';

class ActivitySummarySection extends StatelessWidget {
  final String totalTime;

  const ActivitySummarySection({super.key, required this.totalTime});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Text(
          totalTime,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}
