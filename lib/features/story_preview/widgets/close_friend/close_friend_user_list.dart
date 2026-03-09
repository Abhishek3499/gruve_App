import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/models/close_frind_user_model.dart';

import 'close_friend_user_tile.dart';

class CloseFriendUserList extends StatefulWidget {
  const CloseFriendUserList({super.key});

  @override
  State<CloseFriendUserList> createState() => _CloseFriendUserListState();
}

class _CloseFriendUserListState extends State<CloseFriendUserList> {
  List<CloseFrindUserModel> users = [
    CloseFrindUserModel(name: "Skyler", handle: "Skyler@&\$213"),
    CloseFrindUserModel(name: "Luna", handle: "Luna@893"),
    CloseFrindUserModel(name: "Alex", handle: "Alex@777"),
    CloseFrindUserModel(name: "Sophia", handle: "Sophia@341"),
  ];

  @override
  Widget build(BuildContext context) {
    List<CloseFrindUserModel> selected = users
        .where((u) => u.isSelected)
        .toList();

    List<CloseFrindUserModel> suggest = users
        .where((u) => !u.isSelected)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        /// SELECTED USERS
        if (selected.isNotEmpty)
          ...selected.map(
            (user) => CloseFriendUserTile(
              user: user,
              onTap: () {
                setState(() {
                  user.isSelected = !user.isSelected;
                });
              },
            ),
          ),

        if (selected.isNotEmpty) const SizedBox(height: 20),

        /// SUGGEST TITLE
        const Text(
          "Suggest",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),

        const SizedBox(height: 10),

        /// SUGGEST USERS
        ...suggest.map(
          (user) => CloseFriendUserTile(
            user: user,
            onTap: () {
              setState(() {
                user.isSelected = !user.isSelected;
              });
            },
          ),
        ),
      ],
    );
  }
}
