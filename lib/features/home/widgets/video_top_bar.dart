import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/notification/screens/notification_screen.dart';

class VideoTopBar extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabChanged;

  const VideoTopBar({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: SizedBox(
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTab("Subscribed"),
                    const SizedBox(width: 12),
                    Container(
                      height: 20,
                      width: 1.5,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 12),
                    _buildTab("For you"),
                  ],
                ),
                Positioned(
                  right: 16,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: SizedBox(
                          height: 25,
                          width: 25,
                          child: Image.asset(
                            AppAssets.notification1,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text) {
    final bool isSelected = selectedTab == text;

    return GestureDetector(
      onTap: () => onTabChanged(text),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Syncopate',
              color: isSelected ? const Color(0xFF280131) : Colors.white,
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 1,
            width: isSelected ? 80 : 0,
            color: const Color(0xFF280131),
          ),
        ],
      ),
    );
  }
}
