import 'package:flutter/material.dart';

class ActivityDescriptionSection extends StatelessWidget {
  final String description;

  const ActivityDescriptionSection({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          height: 1.95,
          letterSpacing: 0,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}
