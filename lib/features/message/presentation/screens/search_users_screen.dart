import 'package:flutter/material.dart';
import 'package:gruve_app/features/search/presentation/widgets/search_bar.dart';

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
                  BackButton(
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, color: Colors.white54, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Search functionality coming soon',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use the conversation list to chat',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
