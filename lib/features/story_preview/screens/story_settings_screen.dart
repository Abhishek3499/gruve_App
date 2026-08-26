import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/widgets/more_widgets/more_header.dart';
import 'package:gruve_app/features/story_preview/widgets/more_widgets/replying_card.dart';
import 'package:gruve_app/features/story_preview/widgets/more_widgets/view_card.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class StorySettingsScreen extends StatelessWidget {
  const StorySettingsScreen({super.key});

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
            colors: [Color(0xFF42174C), Color(0xFF9544A7)],
          ),
        ),
        child: Stack(
          children: [
            /// HEADER
            MoreHeader(
              onBack: () {
                Navigator.pop(context);
              },
            ),

            /// CARDS
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  const ReplyingCard(),
                  SizedBox(height: context.rh(33)),
                  const ViewCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
