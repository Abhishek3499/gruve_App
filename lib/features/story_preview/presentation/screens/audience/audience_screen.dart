import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

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
          title: Text(
            "Audience",
            style: TextStyle(color: Colors.white, fontSize: context.rf(20)),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(context.rw(20.0)),
          child: Column(
            children: [
              // The Main Purple Card
              Container(
                padding: EdgeInsets.all(context.rw(20)),
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
                    Text(
                      "How can see your reel",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.rf(14),
                      ),
                    ),
                    SizedBox(height: context.rh(20)),

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

                    SizedBox(height: context.rh(15)),
  
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
        Icon(icon, color: Colors.white, size: context.rw(24)),
        SizedBox(width: context.rw(15)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: context.rf(16)),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: context.rf(12),
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
