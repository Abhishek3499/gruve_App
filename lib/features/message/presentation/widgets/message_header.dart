import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/search/domain/entities/search_navigation_type.dart';
import 'package:gruve_app/features/search/presentation/screens/search_page.dart';
import 'package:gruve_app/features/message/presentation/controller/message_provider.dart';
import 'package:gruve_app/features/message/presentation/widgets/message_avatar_list.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class MessageHeader extends StatelessWidget {
  const MessageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.messagebg), // 👈 YOUR BG IMAGE
          fit: BoxFit.cover,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          /// ===== TOP BAR =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// Title
                const Text(
                  "Chat",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    fontFamily: 'syncopate',
                  ),
                ),

                /// Search
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () async {
                      AppLogger.d(
                        '🔍 [MessageHeader] Opening search from message header',
                      );
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchPage(
                            navigationType: SearchNavigationType.chat,
                          ),
                        ),
                      );
                      if (context.mounted) {
                        AppLogger.d(
                          '🔄 [MessageHeader] Returned from search page - refreshing list',
                        );
                        unawaited(
                          context.read<MessageProvider>().fetchConversations(
                            refresh: true,
                          ),
                        );
                      }
                    },
                    child: Image.asset(
                      AppAssets.search2,
                      width: 28,
                      height: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          /// ===== AVATAR LIST =====
          SizedBox(height: 90, child: const MessageAvatarList()),
        ],
      ),
    );
  }
}
