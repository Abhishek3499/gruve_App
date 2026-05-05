import 'package:flutter/material.dart';
import '../../../core/assets.dart';
import '../../search/widgets/search_bar.dart';
import '../widgets/user_list_item.dart';
import '../data/dummy_search_users.dart';

class SearchUsersScreen extends StatelessWidget {
  const SearchUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C0B21), // Match chat screen background
      body: SafeArea(
        child: Column(
          children: [
            // Header Row
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      AppAssets.back,
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const CustomSearchBar(
                    hintText: 'Search users',
                    borderRadius: 25,
                    borderWidth: 4,
                    backgroundGradient: LinearGradient(
                      colors: [Color(0xFF72008D), Color(0xFF511263)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 23,
                    ),
                    hintStyle: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

            // User List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: DummySearchUsers.getSearchUsers().length,

                itemBuilder: (context, index) {
                  final user = DummySearchUsers.getSearchUsers()[index];
                  return UserListItem(user: user, onTap: () {});
                },

                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
