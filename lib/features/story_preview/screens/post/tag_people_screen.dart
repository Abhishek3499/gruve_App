import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/message/models/message_model.dart';
import 'package:gruve_app/features/story_preview/screens/post/tag_users_screen.dart';

class TagPeopleScreen extends StatefulWidget {
  final String mediaPath;

  const TagPeopleScreen({super.key, required this.mediaPath});

  @override
  State<TagPeopleScreen> createState() => _TagPeopleScreenState();
}

class _TagPeopleScreenState extends State<TagPeopleScreen> {
  List<ChatUser> selectedUsers = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.8),
            colors: [Color(0xFF2A0944), Color(0xFF0D0214)],
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// 1. CUSTOM HEADER (Back, Title, Done)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        AppAssets.back,
                        color: Colors.white,
                        height: 24,
                      ),
                    ),
                    const Text(
                      "Tag People",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, selectedUsers); // ✅ MUST
                      },
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          color: Color(0xFF007AFF), // iOS Blue color
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// 2. MAIN CONTENT
              SizedBox(height: 30),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 1. MEDIA PREVIEW
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.75,
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: _buildMediaPreview(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ 2. YAHI ADD KARNA HAI (Selected Users List)
                    if (selectedUsers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: selectedUsers.map((user) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundImage: user.avatar.startsWith('http')
                                    ? NetworkImage(user.avatar)
                                    : AssetImage(user.avatar) as ImageProvider,
                              ),
                              title: Text(
                                user.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                user.name,
                                style: const TextStyle(color: Colors.white54),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedUsers.remove(user);
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // 3. TAP TO TAG BUTTON (already hai)
                    GestureDetector(
                      onTap: () async {
                        final users = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TagUsersScreen(),
                          ),
                        );

                        if (users != null && users is List) {
                          setState(() {
                            selectedUsers = List<ChatUser>.from(users);
                          });
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Tap to Tag People",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (widget.mediaPath.startsWith('http')) {
      return Image.network(
        widget.mediaPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      final file = File(widget.mediaPath);
      // Check for video formats
      if (widget.mediaPath.toLowerCase().endsWith('.mp4') ||
          widget.mediaPath.toLowerCase().endsWith('.mov')) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
          ),
        );
      }
      return Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }
}
