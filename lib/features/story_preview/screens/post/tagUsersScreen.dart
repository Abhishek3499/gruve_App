import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/message/data/dummy_search_users.dart';
import 'package:gruve_app/features/message/models/message_model.dart';
import 'package:gruve_app/features/story_preview/widgets/hide_story_widgets/searchbar_re.dart';

class TagUsersScreen extends StatefulWidget {
  const TagUsersScreen({super.key});

  @override
  State<TagUsersScreen> createState() => _TagUsersScreenState();
}

class _TagUsersScreenState extends State<TagUsersScreen> {
  List<ChatUser> selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    final users = DummySearchUsers.getSearchUsers();

    return Scaffold(
      backgroundColor: const Color(0xFF1C0B21),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      AppAssets.back,
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                  ),

                  const Text(
                    "Tag People",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, selectedUsers);
                    },
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SearchbarRe(hintText: 'Search users'),
            ),

            const SizedBox(height: 10),

            // Users List
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];

                  final isSelected = selectedUsers.contains(user);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(user.avatar),
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      user.name,
                      style: const TextStyle(color: Colors.white54),
                    ),

                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,

                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedUsers.removeWhere((u) => u.id == user.id);
                        } else {
                          selectedUsers.add(user);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
