import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/profile_menu_drawer/models/blocked/blocked_user_model.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/blocked/blocked_footer.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/blocked/blocked_header.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/blocked/blocked_tile.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/blocked/unblock_widget.dart';

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<BlockedUserModel> users = [
      BlockedUserModel(
        image: AppAssets.blocked1,
        name: "Unfold Co",
        username: "Unfold2332Co",
      ),
      BlockedUserModel(
        image: AppAssets.blocked2,
        name: "Unfold Co",
        username: "Unfold2332Co",
      ),
      BlockedUserModel(
        image: AppAssets.blocked3,
        name: "Unfold Co",
        username: "Unfold2332Co",
      ),
      BlockedUserModel(
        image: AppAssets.blocked2,
        name: "Unfold Co",
        username: "Unfold2332Co",
      ),
      BlockedUserModel(
        image: AppAssets.blocked1,
        name: "Unfold Co",
        username: "Unfold2332Co",
      ),
      BlockedUserModel(
        image: AppAssets.saved1,
        name: "Unfold Co",
        username: "Unfold2332Co",
      ),
      BlockedUserModel(
        image: AppAssets.blocked3,
        name: "Unfold Co",
        username: "Unfold2332Co",
      ),
      BlockedUserModel(
        image: AppAssets.blocked1,
        name: "Unfold Co",
        username: "Unfold2332Co",
      ),
      BlockedUserModel(
        image: AppAssets.blocked2,
        name: "Unfold Co",
        username: "Unfold2332Co",
      ),
      BlockedUserModel(
        image: AppAssets.blocked3,
        name: "Unfold Co",
        username: "Unfold2332Co",
      ),
      BlockedUserModel(
        image: AppAssets.blocked2,
        name: "Unfold Co",
        username: "Unfold2332Co",
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF14001A),
      body: SafeArea(
        child: Column(
          children: [
            /// ===== HEADER =====
            const BlockedHeader(),

            /// ===== USER LIST =====
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return BlockedUserTile(
                    image: user.image,
                    name: user.name,
                    username: user.username,
                    onUnblock: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.7),
                        builder: (context) {
                          return UnblockWidget(
                            name: user.name,
                            username: user.username,
                            onConfirm: () {
                              debugPrint("User Unblocked");
                            },
                          );
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
