import 'package:flutter/material.dart';

class ActivityDescriptionSection extends StatelessWidget {
  final String description;

  const ActivityDescriptionSection({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF7F8C8D),
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
