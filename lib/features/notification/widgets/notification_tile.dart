import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class NotificationTile extends StatelessWidget {
  final String username;
  final String message;
  final String time;
  final String profileImage;
  final String? postImage;
  final bool isRead;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.username,
    required this.message,
    required this.time,
    required this.profileImage,
    this.postImage,
    this.isRead = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the image provider
    ImageProvider avatarProvider;
    if (profileImage.startsWith('http://') || profileImage.startsWith('https://')) {
      avatarProvider = NetworkImage(profileImage);
    } else if (profileImage.isNotEmpty) {
      avatarProvider = AssetImage(profileImage);
    } else {
      avatarProvider = const AssetImage(AppAssets.nprofile);
    }

    ImageProvider? thumbnailProvider;
    if (postImage != null) {
      if (postImage!.startsWith('http://') || postImage!.startsWith('https://')) {
        thumbnailProvider = NetworkImage(postImage!);
      } else {
        thumbnailProvider = AssetImage(postImage!);
      }
    }

    return InkWell(
      onTap: onTap,
      splashColor: Colors.white12,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Unread dot indicator
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFC06CFF),
                  shape: BoxShape.circle,
                ),
              ),
            CircleAvatar(radius: 20, backgroundImage: avatarProvider),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$username $message",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isRead ? Colors.white.withValues(alpha: 0.85) : Colors.white,
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      color: isRead ? Colors.white60 : Colors.white70,
                      fontSize: 11,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (postImage != null && thumbnailProvider != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Image(image: thumbnailProvider, fit: BoxFit.cover),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
