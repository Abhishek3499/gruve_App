import 'package:flutter/material.dart';
import 'package:gruve_app/features/search/widgets/search_bar.dart';
import 'package:gruve_app/features/story_preview/widgets/hide_story_widgets/done_button.dart';
import 'package:gruve_app/features/story_preview/widgets/hide_story_widgets/hide_story_header.dart';
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

            const CustomSearchBar(
              hintText: 'Search',
              width: 362,
              borderRadius: 25,
              borderWidth: 4,
              backgroundGradient: LinearGradient(
                colors: [Color(0xFF72008D), Color(0xFF511263)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.white, size: 23),
              hintStyle: TextStyle(color: Colors.white, fontSize: 14),
            ),

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
