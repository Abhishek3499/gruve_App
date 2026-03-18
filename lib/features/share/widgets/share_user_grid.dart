import 'package:flutter/material.dart';

import '../data/dummy_share_users.dart';
import '../models/share_user_model.dart';
import 'share_user_item.dart';

class ShareUserGrid extends StatefulWidget {
  const ShareUserGrid({super.key});

  @override
  State<ShareUserGrid> createState() => _ShareUserGridState();
}

class _ShareUserGridState extends State<ShareUserGrid> {
  final TextEditingController _searchController = TextEditingController();
  List<ShareUserModel> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = DummyShareUsers.getShareUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredUsers = DummyShareUsers.getFilteredUsers(query);
    });
  }

  void _onUserTap(ShareUserModel user) {
    // Handle user selection for sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared with ${user.username}'),
        backgroundColor: const Color(0xFF7A1FA2),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Color(0x33FFFFFF), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.white, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Users grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              return ShareUserItem(user: user, onTap: () => _onUserTap(user));
            },
          ),
        ),
      ],
    );
  }
}
