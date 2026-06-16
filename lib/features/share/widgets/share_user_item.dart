import 'package:flutter/material.dart';
import 'package:gruve_app/features/search/data/user_search/user_search_service.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/widgets/app_cached_image.dart';

class ShareUserItem extends StatelessWidget {
  final SearchUser user;
  final VoidCallback? onTap;
  final bool isSelected;

  const ShareUserItem({
    super.key,
    required this.user,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with online indicator or selection checkmark
            Stack(
              children: [
                // Profile avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFD42BC2)
                          : Colors.white.withValues(alpha: 0.3),
                      width: isSelected ? 2.5 : 2,
                    ),
                  ),
                  child: ClipOval(
                    child: user.avatar.isNotEmpty
                        ? AppCachedImage(
                            imageUrl: user.avatar,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: Colors.grey.shade600,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          )
                        : const Image(
                            image: AssetImage(AppAssets.profile),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),

                // Online indicator
                if (user.isOnline && !isSelected)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),

                // Selected indicator checkmark
                if (isSelected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD42BC2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Username
            SizedBox(
              width: 70,
              child: Text(
                user.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
