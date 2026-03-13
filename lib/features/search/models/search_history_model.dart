enum SearchType { user, hashtag, music }

class SearchHistoryModel {
  final String id;
  final String query;
  final SearchType type;
  final String subtitle;
  final String? avatar;

  SearchHistoryModel({
    required this.id,
    required this.query,
    required this.type,
    required this.subtitle,
    this.avatar,
  });
}
