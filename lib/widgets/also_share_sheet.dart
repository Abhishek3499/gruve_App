import 'package:flutter/material.dart';

class AlsoShareSheet extends StatefulWidget {
  const AlsoShareSheet({super.key});

  @override
  State<AlsoShareSheet> createState() => _AlsoShareSheetState();
}

class _AlsoShareSheetState extends State<AlsoShareSheet> {
  final TextEditingController _searchController = TextEditingController();
  final List<UserModel> _allUsers = [
    UserModel(name: 'Your Story', username: '@candice', isSelected: false),
    UserModel(name: 'Alex Johnson', username: '@alexj', isSelected: false),
    UserModel(name: 'Sarah Williams', username: '@sarahw', isSelected: false),
    UserModel(name: 'Mike Davis', username: '@miked', isSelected: false),
    UserModel(name: 'Emma Wilson', username: '@emmaw', isSelected: false),
    UserModel(name: 'Chris Brown', username: '@chrisb', isSelected: false),
    UserModel(name: 'Lisa Anderson', username: '@lisaa', isSelected: false),
    UserModel(name: 'David Miller', username: '@davidm', isSelected: false),
  ];
  List<UserModel> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = List.from(_allUsers);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = _allUsers.where((user) =>
          user.name.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  void _toggleUserSelection(int index) {
    setState(() {
      _filteredUsers[index].isSelected = !_filteredUsers[index].isSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          const Text(
            'Share',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSearchBar(),
          ),

          const SizedBox(height: 20),

          // Users List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                return _UserListTile(
                  user: _filteredUsers[index],
                  onShareTap: () => _toggleUserSelection(index),
                );
              },
            ),
          ),

          // Done Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildDoneButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
        ),
      ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          color: const Color(0xFF1E1A2E),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search users...',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 16),
            prefixIcon: Icon(Icons.search, color: Colors.white54, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        final selectedUsers = _allUsers.where((user) => user.isSelected).toList();
        debugPrint('Sharing with ${selectedUsers.length} users');
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF72008D),
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Done',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class UserModel {
  final String name;
  final String username;
  bool isSelected;

  UserModel({
    required this.name,
    required this.username,
    this.isSelected = false,
  });
}

class _UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onShareTap;

  const _UserListTile({
    required this.user,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[600],
            backgroundImage: user.name == 'Your Story'
                ? const NetworkImage('https://i.pravatar.cc/150?u=candice')
                : null,
            child: user.name != 'Your Story'
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.username,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Share Button
          GestureDetector(
            onTap: onShareTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: user.isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF9B27AF), Color(0xFF6A0DAD)],
                      )
                    : null,
                color: user.isSelected ? null : Colors.transparent,
                border: user.isSelected
                    ? null
                    : Border.all(color: Colors.white38, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                user.isSelected ? 'Shared' : 'Share',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
