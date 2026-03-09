import 'package:flutter/material.dart';
import 'user_list_item.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  int selectedIndex = -1;

  final users = const [
    {"username": "Skyler", "handle": "Skyler@&213"},
    {"username": "Luna", "handle": "Luna@893"},
    {"username": "Alex", "handle": "Alex@777"},
    {"username": "Sophia", "handle": "Sophia@341"},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: UserListItem(
            username: users[index]["username"]!,
            handle: users[index]["handle"]!,
            isSelected: selectedIndex == index,
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}
