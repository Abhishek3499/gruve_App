import 'package:flutter/material.dart';
import 'story_share_sheet.dart';

// Example of how to properly call StoryShareSheet to avoid overflow
class StoryShareSheetExample {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const StoryShareSheet(),
      ),
    );
  }
}
