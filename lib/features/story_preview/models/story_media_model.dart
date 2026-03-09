class StoryMediaModel {
  final String mediaPath;
  final MediaType mediaType;
  final DateTime createdAt;

  StoryMediaModel({
    required this.mediaPath,
    required this.mediaType,
    required this.createdAt,
  });
}

enum MediaType {
  image,
  video,
}
