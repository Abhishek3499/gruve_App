import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/user_profile/presentation/controller/block_provider.dart';
import 'package:gruve_app/features/blocked/presentation/widgets/blocked_footer.dart';
import 'package:gruve_app/features/blocked/presentation/widgets/blocked_header.dart';
import 'package:gruve_app/features/blocked/presentation/widgets/blocked_tile.dart';
import 'package:gruve_app/features/blocked/presentation/widgets/unblock_widget.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

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
      context.read<BlockProvider>().fetchBlockedUsers(forceRefresh: true);
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
                    return Center(
                      child: Text(
                        'No blocked users',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: context.rf(16),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(top: context.rh(10)),
                    itemCount: provider.blockedUsers.length,
                    itemBuilder: (context, index) {
                      final user = provider.blockedUsers[index];
                      return BlockedUserTile(
                        image: user.image,
                        name: user.name,
                        username: user.username,
                        onUnblock: () async {
                          AppLogger.d('🟢 Unblock button tapped');
                          // Save references BEFORE async operations
                          final blockProvider = context.read<BlockProvider>();
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          
                          AppLogger.d('🟢 Opening dialog...');
                          final result = await showDialog<bool>(
                            context: context,
                            barrierColor: Colors.black.withValues(alpha: 0.7),
                            builder: (dialogContext) {
                              return UnblockWidget(
                                name: user.name,
                                username: user.username,
                                onConfirm: () {
                                  AppLogger.d('🟢 Yes button clicked, popping with true');
                                  Navigator.of(dialogContext).pop(true);
                                },
                              );
                            },
                          );

                          AppLogger.d('🟢 Dialog result: $result');
                          
                          if (result == true) {
                            AppLogger.d('🟢 Result is true, showing loading snackbar...');
                            
                            // 🚀 INSTANT LOADING SNACKBAR
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      width: context.rw(20),
                                      height: context.rh(20),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: context.rw(12)),
                                    Expanded(
                                      child: Text(
                                        'Unblocking ${user.name}...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: context.rf(14),
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
                                margin: EdgeInsets.symmetric(horizontal: context.rw(16), vertical: context.rh(16)),
                                duration: const Duration(milliseconds: 500),
                                elevation: 8,
                              ),
                            );
                            
                            AppLogger.d('🟢 Calling API...');
                            try {
                              await blockProvider.toggleBlockUser(
                                user.userId,
                                refreshList: true,
                              );

                              if (!mounted) return;

                              AppLogger.d('🟢 API success, showing success snackbar...');
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white, size: context.rw(20)),
                                      SizedBox(width: context.rw(12)),
                                      Expanded(
                                        child: Text(
                                          '${user.name} unblocked successfully',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: context.rf(14),
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
                                  margin: EdgeInsets.symmetric(horizontal: context.rw(16), vertical: context.rh(16)),
                                  duration: const Duration(milliseconds: 1500),
                                  elevation: 8,
                                ),
                              );
                              AppLogger.d('🟢 Success snackbar shown!');
                            } catch (e) {
                              AppLogger.d('🔴 Error: $e');
                              AppLogger.d('Error unblocking user: $e');

                              if (!mounted) return;

                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.white, size: context.rw(20)),
                                      SizedBox(width: context.rw(12)),
                                      Expanded(
                                        child: Text(
                                          'Failed to unblock user',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: context.rf(14),
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
                                  margin: EdgeInsets.symmetric(horizontal: context.rw(16), vertical: context.rh(16)),
                                  duration: const Duration(milliseconds: 1500),
                                  elevation: 8,
                                ),
                              );
                            }
                          } else {
                            AppLogger.d('🟡 Dialog cancelled or result is: $result');
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
