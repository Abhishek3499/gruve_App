import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/user_profile/providers/block_provider.dart';
import '../../../../core/assets.dart';
import 'option_button.dart';
import 'option_item.dart';
import '../sheets/simple_report_sheet.dart';
import '../sheets/simple_block_sheet.dart';
import '../sheets/simple_not_interested_sheet.dart';

class VideoOptionsSheet extends StatefulWidget {
  final String userId;
  final String? currentUserId;
  final String? userName;
  final String? profileImage;
  
  const VideoOptionsSheet({
    super.key, 
    required this.userId, 
    this.currentUserId,
    this.userName,
    this.profileImage,
  });

  @override
  State<VideoOptionsSheet> createState() => _VideoOptionsSheetState();
}

class _VideoOptionsSheetState extends State<VideoOptionsSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleAction(String action) {
    HapticFeedback.lightImpact();

    // Show custom overlay notification
    _showActionSnackBar('$action feature coming soon!', context);

    // Close the sheet
    Navigator.of(context).pop();
  }

  void _showActionSnackBar(String message, BuildContext context) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFCD72E3),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (overlayEntry != null) {
                      overlayEntry.remove();
                    }
                  },
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(overlayEntry);

    // Auto-remove after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry != null) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = widget.currentUserId != null && widget.currentUserId == widget.userId;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 50),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              height: isSelf 
                  ? MediaQuery.of(context).size.height * 0.35
                  : MediaQuery.of(context).size.height * 0.50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFCD72E3), Color(0xFF3C034A)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Top action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OptionButton(
                          icon: AppAssets.savs,
                          label: 'Save',
                          onTap: () => _handleAction('Save'),
                        ),
                        OptionButton(
                          icon: AppAssets.coll,
                          label: 'Collab',
                          onTap: () => _handleAction('Collab'),
                        ),
                        OptionButton(
                          icon: AppAssets.remixx,
                          label: 'Remix',
                          onTap: () => _handleAction('Remix'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Menu list
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (!isSelf) OptionItem(
                            title: 'Not interested',
                            icon: AppAssets.eye,
                            onTap: () {
                              Navigator.of(context).pop();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    const SimpleNotInterestedSheet(),
                              );
                            },
                          ),
                          if (!isSelf) const SizedBox(height: 12),
                          OptionItem(
                            title: 'Download',
                            icon: AppAssets.downloads,
                            onTap: () => _handleAction('Download'),
                          ),
                          if (!isSelf) const SizedBox(height: 12),
                          if (!isSelf) OptionItem(
                            title: 'Block',
                            icon: AppAssets.blocks,
                            onTap: () async {
                              print('🔴 Block button tapped in VideoOptionsSheet');
                              
                              // Save references BEFORE any async operation
                              final blockProvider = context.read<BlockProvider>();
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              
                              print('🔴 Closing VideoOptionsSheet...');
                              navigator.pop();
                              
                              print('🔴 Opening SimpleBlockSheet...');
                              final result = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => SimpleBlockSheet(
                                  userName: widget.userName,
                                  profileImage: widget.profileImage,
                                ),
                              );

                              print('🔴 SimpleBlockSheet returned: $result');

                              // If user confirmed block action
                              if (result == true) {
                                print('🔴 User confirmed block');
                                
                                // 🚀 INSTANT SNACKBAR - Show immediately
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
                                            'Blocking ${widget.userName ?? "user"}...',
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
                                
                                // API call in background
                                try {
                                  await blockProvider.toggleBlockUser(widget.userId);
                                  print('🔴 API call completed');
                                  
                                  final isBlocked = blockProvider.isBlocked(widget.userId);
                                  print('🔴 Block status: $isBlocked');
                                  
                                  // Success snackbar
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              '${widget.userName ?? "User"} blocked successfully',
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
                                } catch (e) {
                                  print('🔴 Error: $e');
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.white, size: 20),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text(
                                              'Failed to block user',
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
                                print('🔴 User cancelled');
                              }
                            },
                          ),
                          if (!isSelf) const SizedBox(height: 12),
                          if (!isSelf) OptionItem(
                            title: 'Report',
                            icon: AppAssets.reports,
                            iconColor: Colors.red,
                            textColor: Colors.red,
                            hasArrow: true,
                            onTap: () {
                              Navigator.of(context).pop();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const SimpleReportSheet(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
