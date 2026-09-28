import 'package:flutter/material.dart';
import 'package:gruve_app/core/services/media_upload_service.dart';

/// Thin banner shown below the header while a media upload runs in background.
class UploadProgressBanner extends StatelessWidget {
  final String mediaKind;
  final UploadStatus status;

  const UploadProgressBanner({
    super.key,
    required this.mediaKind,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final label = status == UploadStatus.sending
        ? 'Sending $mediaKind…'
        : 'Uploading $mediaKind…';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white.withValues(alpha: 0.08),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
