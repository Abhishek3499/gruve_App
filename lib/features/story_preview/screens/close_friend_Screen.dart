import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/widgets/close_friend/close_friend_header.dart';
import 'package:gruve_app/features/story_preview/widgets/close_friend/close_friend_user_list.dart';
import 'package:gruve_app/features/story_preview/widgets/hide_story_widgets/done_button.dart';
import 'package:gruve_app/features/story_preview/widgets/hide_story_widgets/searchbar_re.dart';

class CloseFriendScreen extends StatelessWidget {
  const CloseFriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 74, 5, 90),
              Color.fromARGB(255, 25, 2, 31),
            ],
          ),
        ),

        child: Column(
          children: [
            /// HEADER
            CloseFriendHeader(
              onBack: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 10),

            const SearchbarRe(hintText: 'Search'),

            const SizedBox(height: 20),

            /// MULTI SELECT USER LIST
            const Expanded(child: CloseFriendUserList()),

            /// DONE BUTTON
            Padding(
              padding: const EdgeInsets.all(20),
              child: DoneButton(
                onDone: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
