/// Model for cursor-based pagination
/// Handles cursor information for fetching next/previous pages
class CursorModel {
  /// ISO formatted timestamp for cursor position
  final String? createdAt;
  
  /// Integer ID for cursor position (NOT post.id)
  final int? id;

  const CursorModel({
    this.createdAt,
    this.id,
  });

  /// Create from JSON response
  factory CursorModel.fromJson(Map<String, dynamic> json) {
    return CursorModel(
      createdAt: json['created_at']?.toString(),
      id: json['id'] as int?,
    );
  }

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    if (createdAt == null || id == null) return {};
    
    return {
      'cursor_created_at': createdAt,
      'cursor_id': id,
    };
  }

  /// Check if cursor is valid (has both values)
  bool get isValid => createdAt != null && id != null;

  /// Create empty cursor for initial request
  static const CursorModel empty = CursorModel();

  @override
  String toString() => 'CursorModel(createdAt: $createdAt, id: $id)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CursorModel &&
          runtimeType == other.runtimeType &&
          createdAt == other.createdAt &&
          id == other.id;

  @override
  int get hashCode => createdAt.hashCode ^ id.hashCode;
}
