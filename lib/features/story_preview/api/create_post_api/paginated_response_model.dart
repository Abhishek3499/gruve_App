import 'package:gruve_app/features/story_preview/api/create_post_api/cursor_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';

/// Model for paginated API response
/// Contains posts, cursor info, and pagination state
class PaginatedPostsResponse {
  /// List of posts for current page
  final List<Post> posts;

  /// Cursor for next page (null if no more pages)
  final CursorModel? nextCursor;

  /// Whether more posts are available
  final bool hasMore;

  const PaginatedPostsResponse({
    required this.posts,
    this.nextCursor,
    required this.hasMore,
  });

  @override
  String toString() =>
      'PaginatedPostsResponse(posts: ${posts.length}, hasMore: $hasMore)';
}
