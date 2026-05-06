import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import '../../search/screens/search_page.dart';
import 'message_avatar_list.dart';

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
                /// Back
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      AppAssets.back,
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                  ),
                ),

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
                    onTap: () {
                      debugPrint('🔍 [MessageHeader] Opening search from message header');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchPage(),
                        ),
                      );
                    },
                    child: Image.asset(
                      AppAssets.search2,
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 45),

          /// ===== AVATAR LIST =====
          const MessageAvatarList(),
        ],
      ),
    );
  }
}
