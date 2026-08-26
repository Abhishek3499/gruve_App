import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/search/data/user_search/user_search_service.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/message/models/message_model.dart';
import 'package:gruve_app/features/search/widgets/search_bar.dart';
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/features/message/presentation/provider/user_provider.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class TagUsersScreen extends StatefulWidget {
  const TagUsersScreen({super.key});

  @override
  State<TagUsersScreen> createState() => _TagUsersScreenState();
}

class _TagUsersScreenState extends State<TagUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DebouncedUserSearch _userSearch = DebouncedUserSearch();
  final List<ChatUser> selectedUsers = [];
  List<SearchUser> _users = [];
  bool _isSearching = false;
  String? _searchError;
  late final ScrollController _scrollController;
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProvider>().fetchUsers(reason: 'initial');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userSearch.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Only paginate general users list, not search queries
    if (_searchController.text.trim().isNotEmpty) return;

    final provider = context.read<UserProvider>();
    if (!_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: provider.isLoading || provider.isFetchingMore,
      hasMore: provider.hasNext,
    )) {
      return;
    }

    provider.fetchUsers(loadMore: true, reason: 'scroll');
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchError = null;
      _isSearching = query.trim().isNotEmpty;
      if (query.trim().isEmpty) {
        _users = [];
      }
    });

    if (query.trim().isEmpty) {
      _userSearch.clear();
      return;
    }

    _userSearch.search(
      query,
      onResults: (users) {
        if (!mounted) return;
        setState(() {
          _users = users;
          _isSearching = false;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _users = [];
          _isSearching = false;
          _searchError = 'Unable to search users right now';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1C0B21),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(context.rw(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BackButton(
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),

                  Text(
                    "Tag People",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.rf(18),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context, selectedUsers);
                    },
                    child: Text(
                      "Done",
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: context.rf(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rw(16)),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: 'Search users',
                backgroundColor: const Color(0xFF511263),
                backgroundGradient: const LinearGradient(
                  colors: [Color(0xFF72008D), Color(0xFF511263)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: 25,
                borderWidth: 4,
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white,
                  size: context.rw(23),
                ),
                hintStyle: TextStyle(
                  color: Colors.white,
                  fontSize: context.rf(14),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            SizedBox(height: context.rh(10)),

            // Users List
            Expanded(child: _buildUserList(userProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(UserProvider provider) {
    // 1. Search Results Mode
    if (_searchController.text.trim().isNotEmpty) {
      if (_isSearching) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFD42BC2)),
        );
      }

      if (_searchError != null) {
        return Center(
          child: Text(
            _searchError!,
            style: TextStyle(color: Colors.white54, fontSize: context.rf(14)),
          ),
        );
      }

      if (_users.isEmpty) {
        return Center(
          child: Text(
            'No users found',
            style: TextStyle(color: Colors.white54, fontSize: context.rf(14)),
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isSelected = selectedUsers.any((u) => u.id == user.id);

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.avatar.isNotEmpty
                  ? NetworkImage(user.avatar)
                  : AssetImage(AppAssets.profile) as ImageProvider,
            ),
            title: Text(user.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '@${user.username}',
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
                  selectedUsers.add(_toChatUser(user));
                }
              });
            },
          );
        },
      );
    }

    // 2. General Users List Mode (Initial/Cached List)
    if (provider.isLoading && provider.users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD42BC2)),
      );
    }

    if (provider.errorMessage != null && provider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.errorMessage!,
              style: TextStyle(color: Colors.white70, fontSize: context.rf(14)),
            ),
            SizedBox(height: context.rh(12)),
            ElevatedButton(
              onPressed: () => provider.fetchUsers(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 120, 2, 99),
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final generalUsers = provider.users;
    if (generalUsers.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: TextStyle(color: Colors.white54, fontSize: context.rf(14)),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: generalUsers.length + (provider.isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == generalUsers.length && provider.isFetchingMore) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: context.rh(16)),
              child: const CircularProgressIndicator(
                color: Color(0xFFD42BC2),
              ),
            ),
          );
        }

        final user = generalUsers[index];
        final isSelected = selectedUsers.any((u) => u.id == user.userId);

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (user.profilePicture != null && user.profilePicture!.isNotEmpty)
                ? NetworkImage(user.profilePicture!)
                : AssetImage(AppAssets.profile) as ImageProvider,
          ),
          title: Text(user.fullName, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '@${user.username}',
            style: const TextStyle(color: Colors.white54),
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedUsers.removeWhere((u) => u.id == user.userId);
              } else {
                selectedUsers.add(ChatUser(
                  id: user.userId,
                  name: user.fullName,
                  avatar: (user.profilePicture != null && user.profilePicture!.isNotEmpty)
                      ? user.profilePicture!
                      : AppAssets.profile,
                  lastMessage: '',
                  lastMessageTime: '',
                ));
              }
            });
          },
        );
      },
    );
  }

  ChatUser _toChatUser(SearchUser user) {
    return ChatUser(
      id: user.id,
      name: user.name,
      avatar: user.avatar.isNotEmpty ? user.avatar : AppAssets.profile,
      lastMessage: '',
      lastMessageTime: '',
    );
  }
}
