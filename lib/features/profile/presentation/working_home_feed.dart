import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/data/models/user_model.dart';
import 'package:gruve_app/features/profile/data/dummy_users.dart';
import 'package:gruve_app/features/profile/presentation/navigation_helper.dart';
import 'package:gruve_app/features/profile/presentation/screens/profile_screen.dart';

class WorkingHomeFeed extends StatelessWidget {
  const WorkingHomeFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final users = DummyUsers.getAllUsers();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Working Home Feed'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User header with working navigation
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // ✅ WORKING: Tappable profile image
                        NavigationHelper.buildTappableAvatar(
                          context: context,
                          user: user,
                          radius: 25,
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // ✅ WORKING: Tappable username
                        Expanded(
                          child: NavigationHelper.buildTappableUsername(
                            context: context,
                            user: user,
                          ),
                        ),
                        
                        // Subscription status
                        Icon(
                          user.isSubscribed ? Icons.notifications : Icons.notifications_none,
                          color: user.isSubscribed ? Colors.purple : Colors.white54,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  
                  // Post content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Post by ${user.username}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap on avatar or username above to view profile',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildActionButton(Icons.favorite, "${user.likes}"),
                        const SizedBox(width: 20),
                        _buildActionButton(Icons.comment, "234"),
                        const SizedBox(width: 20),
                        _buildActionButton(Icons.share, "56"),
                        const Spacer(),
                        _buildActionButton(Icons.bookmark, ""),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        if (count.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(count, style: const TextStyle(color: Colors.white70)),
        ],
      ],
    );
  }
}
