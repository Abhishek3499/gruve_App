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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.0),
            ],
          ),
        ),
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
                      _buildTab("For You"),
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
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
              shadows: [
                Shadow(
                  blurRadius: 4.0,
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(0.0, 1.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFFC358D7),
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC358D7).withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

