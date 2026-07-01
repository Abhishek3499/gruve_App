import 'package:flutter/material.dart';

class AudienceScreen extends StatefulWidget {
  final bool initialIsEveryone;
  final bool initialIsCloseFriends;

  const AudienceScreen({
    super.key,
    this.initialIsEveryone = true,
    this.initialIsCloseFriends = false,
  });

  @override
  State<AudienceScreen> createState() => _AudienceScreenState();
}

class _AudienceScreenState extends State<AudienceScreen> {
  late bool isEveryone;
  late bool isCloseFriends;

  @override
  void initState() {
    super.initState();
    isEveryone = widget.initialIsEveryone;
    isCloseFriends = widget.initialIsCloseFriends;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, {
          'isEveryone': isEveryone,
          'isCloseFriends': isCloseFriends,
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF12031A), // Dark Background
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(
            color: Colors.white,
            onPressed: () => Navigator.pop(context, {
              'isEveryone': isEveryone,
              'isCloseFriends': isCloseFriends,
            }),
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
