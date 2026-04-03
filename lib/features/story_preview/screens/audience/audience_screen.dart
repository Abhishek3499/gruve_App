import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class AudienceScreen extends StatefulWidget {
  const AudienceScreen({super.key});

  @override
  State<AudienceScreen> createState() => _AudienceScreenState();
}

class _AudienceScreenState extends State<AudienceScreen> {
  bool isEveryone = true;
  bool isCloseFriends = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12031A), // Dark Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(AppAssets.back, height: 24, width: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Audience",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // The Main Purple Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF5B0A6C), // Deep purple card
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "How can see your reel",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Everyone Option
                  _buildAudienceTile(
                    icon: Icons.group_outlined,
                    title: "Everyone",
                    value: isEveryone,
                    onChanged: (val) {
                      setState(() {
                        isEveryone = val;
                        if (val) isCloseFriends = false;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  // Close Friends Option
                  _buildAudienceTile(
                    icon: Icons.star_border,
                    title: "Close Friends",
                    subtitle: "3 people  >",
                    value: isCloseFriends,
                    onChanged: (val) {
                      setState(() {
                        isCloseFriends = val;
                        if (val) isEveryone = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for the Rows
  Widget _buildAudienceTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: Colors.grey.shade400,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}
