import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isOnline;

  const MessageAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[600],
              backgroundImage: imageUrl.isNotEmpty 
                  ? CachedNetworkImageProvider(imageUrl) 
                  : null,
              child: imageUrl.isEmpty 
                  ? const Icon(Icons.person, size: 30, color: Colors.white)
                  : null,
            ),

            /// Online green dot
            if (isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 6),

        Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
