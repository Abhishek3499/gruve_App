import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/notification/screens/notification_screen.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/notification/providers/notification_provider.dart';

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
                    child: Consumer<NotificationProvider>(
                      builder: (context, provider, _) {
                        final count = provider.unreadCount;
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationScreen(),
                              ),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
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
                              if (count > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B30), // Premium vibrant iOS red
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.black, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      count > 99 ? '99+' : '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Outfit',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
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

