import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/widgets/hide_story_widgets/done_button.dart';
import 'package:gruve_app/features/story_preview/widgets/hide_story_widgets/hide_story_header.dart';
import 'package:gruve_app/features/story_preview/widgets/hide_story_widgets/searchbar_re.dart';
import 'package:gruve_app/features/story_preview/widgets/hide_story_widgets/user_list.dart';

class HideStoryScreen extends StatelessWidget {
  const HideStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        /// BACKGROUND
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF42174C), Color(0xFF9544A7)],
          ),
        ),

        child: Column(
          children: [
            /// HEADER
            HideStoryHeader(
              onBack: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 20),

            const SearchbarRe(),

            const SizedBox(height: 20),

            /// USER LIST
            const Expanded(child: UserList()),

            /// PUSH BUTTON TO BOTTOM

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
