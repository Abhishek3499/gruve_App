import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/user_profile/providers/block_provider.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/blocked/blocked_footer.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/blocked/blocked_header.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/blocked/blocked_tile.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/blocked/unblock_widget.dart';

class BlockedScreen extends StatefulWidget {
  const BlockedScreen({super.key});

  @override
  State<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<BlockedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlockProvider>().fetchBlockedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14001A),
      body: SafeArea(
        child: Column(
          children: [
            const BlockedHeader(),
            Expanded(
              child: Consumer<BlockProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoadingList) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFCD72E3),
                      ),
                    );
                  }

                  if (provider.blockedUsers.isEmpty) {
                    return const Center(
                      child: Text(
                        'No blocked users',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: provider.blockedUsers.length,
                    itemBuilder: (context, index) {
                      final user = provider.blockedUsers[index];
                      return BlockedUserTile(
                        image: user.image,
                        name: user.name,
                        username: user.username,
                        onUnblock: () async {
                          debugPrint('🟢 Unblock button tapped');
                          // Save references BEFORE async operations
                          final blockProvider = context.read<BlockProvider>();
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          
                          debugPrint('🟢 Opening dialog...');
                          final result = await showDialog<bool>(
                            context: context,
                            barrierColor: Colors.black.withValues(alpha: 0.7),
                            builder: (dialogContext) {
                              return UnblockWidget(
                                name: user.name,
                                username: user.username,
                                onConfirm: () {
                                  debugPrint('🟢 Yes button clicked, popping with true');
                                  Navigator.of(dialogContext).pop(true);
                                },
                              );
                            },
                          );

                          debugPrint('🟢 Dialog result: $result');
                          
                          if (result == true) {
                            debugPrint('🟢 Result is true, showing loading snackbar...');
                            
                            // 🚀 INSTANT LOADING SNACKBAR
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Unblocking ${user.name}...',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFFCD72E3),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                duration: const Duration(milliseconds: 500),
                                elevation: 8,
                              ),
                            );
                            
                            debugPrint('🟢 Calling API...');
                            try {
                              await blockProvider.toggleBlockUser(
                                user.userId,
                                refreshList: true,
                              );

                              if (!mounted) return;

                              debugPrint('🟢 API success, showing success snackbar...');
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${user.name} unblocked successfully',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFFCD72E3),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  duration: const Duration(milliseconds: 1500),
                                  elevation: 8,
                                ),
                              );
                              debugPrint('🟢 Success snackbar shown!');
                            } catch (e) {
                              debugPrint('🔴 Error: $e');
                              debugPrint('Error unblocking user: $e');

                              if (!mounted) return;

                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.white, size: 20),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Failed to unblock user',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  duration: const Duration(milliseconds: 1500),
                                  elevation: 8,
                                ),
                              );
                            }
                          } else {
                            debugPrint('🟡 Dialog cancelled or result is: $result');
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const BlockedFooter(),
          ],
        ),
      ),
    );
  }
}
