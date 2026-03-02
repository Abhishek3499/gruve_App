import 'package:flutter/material.dart';

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
            CircleAvatar(radius: 30, backgroundImage: AssetImage(imageUrl)),

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
