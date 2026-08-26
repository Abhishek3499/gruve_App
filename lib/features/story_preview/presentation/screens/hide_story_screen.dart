import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/search/presentation/widgets/search_bar.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/hide_story_widgets/done_button.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/hide_story_widgets/hide_story_header.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/hide_story_widgets/user_list.dart';

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

            SizedBox(height: context.rh(20)),

            CustomSearchBar(
              hintText: 'Search',
              width: 362,
              borderRadius: 25,
              borderWidth: 4,
              backgroundGradient: const LinearGradient(
                colors: [Color(0xFF72008D), Color(0xFF511263)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.white, size: context.rw(23)),
              hintStyle: TextStyle(color: Colors.white, fontSize: context.rf(14)),
            ),

            SizedBox(height: context.rh(20)),

            /// USER LIST
            const Expanded(child: UserList()),

            /// PUSH BUTTON TO BOTTOM

            /// DONE BUTTON
            Padding(
              padding: EdgeInsets.all(context.rw(20)),
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
