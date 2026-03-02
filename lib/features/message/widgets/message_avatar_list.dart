import 'package:flutter/material.dart';
import '../widgets/message_avatar.dart';
import '../../../core/assets.dart';

class MessageAvatarList extends StatelessWidget {
  const MessageAvatarList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> users = [
      {'name': 'Skyler', 'image': AppAssets.profile, 'isOnline': true},
      {'name': 'John', 'image': AppAssets.nprofile, 'isOnline': true},
      {'name': 'Jane', 'image': AppAssets.newprofile, 'isOnline': false},
      {'name': 'Mike', 'image': AppAssets.profile, 'isOnline': true},
      {'name': 'Sarah', 'image': AppAssets.nprofile, 'isOnline': false},
      {'name': 'Jane', 'image': AppAssets.newprofile, 'isOnline': false},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final user = users[index];
          return MessageAvatar(
            name: user['name'],
            imageUrl: user['image'],
            isOnline: user['isOnline'],
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemCount: users.length,
      ),
    );
  }
}
