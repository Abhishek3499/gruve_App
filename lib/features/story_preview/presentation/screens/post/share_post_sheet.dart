import 'package:flutter/material.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:gruve_app/features/story_preview/presentation/screens/post/share_post_screen.dart';

/// Full-height bottom sheet with [SharePostScreen]; pops with same results as push.
Future<String?> showSharePostOnHomeSheet(
  String mediaPath, {
  String? mediaMimeType,
}) async {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return null;

  return showModalBottomSheet<String>(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height;
      return SizedBox(
        height: height * 0.94,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SharePostScreen(
            mediaPath: mediaPath,
            mediaMimeType: mediaMimeType,
          ),
        ),
      );
    },
  );
}
