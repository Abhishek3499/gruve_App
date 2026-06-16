import 'package:flutter/material.dart';
import 'package:gruve_app/features/search/data/user_search/user_search_service.dart';

import '../widgets/share_user_grid.dart';
import '../widgets/share_social_buttons.dart';

class ShareBottomSheet extends StatefulWidget {
  const ShareBottomSheet({super.key});

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final Set<SearchUser> _selectedUsers = {};

  void _toggleUser(SearchUser user) {
    setState(() {
      final exists = _selectedUsers.any((u) => u.id == user.id);
      if (exists) {
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _onSend() {
    if (_selectedUsers.isEmpty) return;

    final names = _selectedUsers.map((u) => u.username).join(', ');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared successfully with $names'),
        backgroundColor: const Color(0xFF7A1FA2),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  Widget _buildSendButton(BuildContext context) {
    return Padding(
      key: const ValueKey('send'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GestureDetector(
        onTap: _onSend,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF3AFF), Color(0xFF72008D)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3AFF).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Send to ${_selectedUsers.length} ${_selectedUsers.length == 1 ? 'person' : 'people'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCD72E3), Color(0xFF3C034A)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 65,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // User grid with search
            Expanded(
              flex: 3,
              child: ShareUserGrid(
                selectedUsers: _selectedUsers,
                onUserToggle: _toggleUser,
              ),
            ),

            // Social share buttons or send button with smooth flow transition
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _selectedUsers.isNotEmpty
                  ? _buildSendButton(context)
                  : const ShareSocialButtons(key: ValueKey('social')),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
