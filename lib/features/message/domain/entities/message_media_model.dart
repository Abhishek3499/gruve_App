/// Uploaded chat media returned from POST .../messages/media/.
class MessageMediaPayload {
  final String mediaUrl;
  final String mediaKey;
  final String mediaMimeType;
  final String mediaKind;

  const MessageMediaPayload({
    required this.mediaUrl,
    required this.mediaKey,
    required this.mediaMimeType,
    required this.mediaKind,
  });

  bool get isVideo => mediaKind.toLowerCase() == 'video';

  factory MessageMediaPayload.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return MessageMediaPayload(
      mediaUrl: data['media_url']?.toString() ?? '',
      mediaKey: data['media_key']?.toString() ?? '',
      mediaMimeType: data['media_mime_type']?.toString() ?? '',
      mediaKind: data['media_kind']?.toString() ?? 'image',
    );
  }

  Map<String, dynamic> toApiPayload() => {
        'media_url': mediaUrl,
        'media_key': mediaKey,
        'media_mime_type': mediaMimeType,
        'media_kind': mediaKind,
      };

  @Deprecated('Use toApiPayload')
  Map<String, dynamic> toSocketPayload() => toApiPayload();
}
