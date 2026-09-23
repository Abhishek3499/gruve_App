/// Cache entry with TTL support
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({required this.data, required this.ttl})
    : createdAt = DateTime.now();

  CacheEntry._({
    required this.data,
    required this.ttl,
    required this.createdAt,
  });

  /// Check if cache entry is still valid
  bool get isValid => DateTime.now().difference(createdAt) < ttl;

  /// Check if cache entry is stale (expired but can be used for stale-while-revalidate)
  bool get isStale => !isValid;

  /// Get cache age
  Duration get age => DateTime.now().difference(createdAt);

  /// Serialize to JSON for disk storage
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'ttl': ttl.inMilliseconds,
    };
  }

  /// Deserialize from JSON
  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return CacheEntry<T>._(
      data: fromJson(json['data']),
      ttl: Duration(milliseconds: json['ttl']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] is int ? json['createdAt'] as int : 0,
      ),
    );
  }
}
