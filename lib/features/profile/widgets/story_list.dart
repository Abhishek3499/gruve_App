import 'package:flutter/material.dart';
import 'package:gruve_app/features/camera/camera_handler.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';

import '../../../core/assets.dart';

class StoryList extends StatelessWidget {
  const StoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 30),
        children: [
          _buildAddStory(context),
          _buildStory(AppAssets.frame1, 'Admin...'),
          _buildStory(AppAssets.frame2, 'Admin...'),
          _buildStory(AppAssets.frame3, 'Admin...'),
          _buildStory(AppAssets.frame2, 'Admin...'),
          _buildStory(AppAssets.frame3, 'Admin...'),
          _buildStory(AppAssets.frame2, 'Admin...'),
          _buildStory(AppAssets.frame1, 'Admin...'),
        ],
      ),
    );
  }

  Widget _buildAddStory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: () async {
          final result = await CameraHandler.openCamera(context);
          if (result == 'start_processing' && context.mounted) {
            PostShareFlowBridge.notifyShareStartProcessing();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF212235),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add Story',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStory(String imagePath, String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: AssetImage(imagePath),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
