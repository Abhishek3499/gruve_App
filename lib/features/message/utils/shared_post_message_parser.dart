/// Detects and parses shared-post / tagged-post payloads inside chat messages.
class SharedPostMessageParser {
  static const _postMessageTypes = {
    'post_share',
    'shared_post',
    'post',
    'post_tag',
    'tagged_post',
    'tag',
    'user_tag',
  };

  static const _previewUrlKeys = [
    'preview_url',
    'previewUrl',
    'thumbnail_url',
    'thumbnailUrl',
    'poster_url',
    'posterUrl',
    'preview_image',
    'previewImage',
    'image_url',
    'imageUrl',
    'cover_url',
    'coverUrl',
    'thumb',
    'poster',
    'cover',
  ];

  static final RegExp _textPostIdRegex = RegExp(
    r'View post:\s*((?:pst_)?[a-zA-Z0-9_\-]+)',
    caseSensitive: false,
  );

  static final RegExp _taggedPostTextRegex = RegExp(
    r'tagged you in a post',
    caseSensitive: false,
  );

  static final RegExp _taggedPostIdRegex = RegExp(
    r'tagged you in a post(?:\s*:\s*|\s+)((?:pst_)?[a-zA-Z0-9_\-]+)',
    caseSensitive: false,
  );

  static final RegExp _barePostIdRegex = RegExp(
    r'\b(pst_[a-zA-Z0-9_\-]+)\b',
    caseSensitive: false,
  );

  static String? extractPostId(Map<String, dynamic> json, String messageText) {
    // Message text is per-share and beats stale nested/metadata fields.
    final fromText = extractPostIdFromText(messageText);
    if (fromText != null) return fromText;

    final messageType = _messageType(json);
    if (_postMessageTypes.contains(messageType)) {
      final directId = _readPostId(json['post_id'] ?? json['postId']);
      if (directId != null) return directId;
    }

    final sharedPost =
        json['shared_post'] ?? json['tagged_post'] ?? json['post'] ?? json['attachment'];
    if (sharedPost is Map) {
      final map = Map<String, dynamic>.from(sharedPost);
      final nestedId = _readPostId(
        map['id'] ?? map['post_id'] ?? map['postId'],
      );
      if (nestedId != null) return nestedId;
    }

    final metadata = json['metadata'];
    if (metadata is Map) {
      final map = Map<String, dynamic>.from(metadata);
      final metaId = _readPostId(map['post_id'] ?? map['postId'] ?? map['id']);
      if (metaId != null) return metaId;
    }

    final content = json['content'];
    if (content is Map) {
      final map = Map<String, dynamic>.from(content);
      final contentType = map['type']?.toString().toLowerCase();
      if (_postMessageTypes.contains(contentType)) {
        final contentId = _readPostId(
          map['post_id'] ?? map['postId'] ?? map['id'],
        );
        if (contentId != null) return contentId;
      }
    }

    return null;
  }

  /// Thumbnail / preview image URL embedded in the message payload.
  static String? extractPreviewUrl(
    Map<String, dynamic> json, {
    String? postId,
  }) {
    final directPostId = _readPostId(json['post_id'] ?? json['postId']);
    if (directPostId != null &&
        postId != null &&
        directPostId == postId) {
      final direct = _readPreviewUrl(json);
      if (direct != null) return direct;
    }

    for (final key in ['shared_post', 'tagged_post', 'post', 'attachment']) {
      final nested = json[key];
      if (nested is Map) {
        final map = Map<String, dynamic>.from(nested);
        final nestedId =
            _readPostId(map['id'] ?? map['post_id'] ?? map['postId']);
        if (postId != null && nestedId != null && nestedId != postId) {
          continue;
        }
        final url = _readPreviewUrl(map);
        if (url != null) return url;
      }
    }

    final metadata = json['metadata'];
    if (metadata is Map) {
      final map = Map<String, dynamic>.from(metadata);
      final metaId = _readPostId(map['post_id'] ?? map['postId'] ?? map['id']);
      if (postId == null || metaId == null || metaId == postId) {
        final url = _readPreviewUrl(map);
        if (url != null) return url;
      }
    }

    final content = json['content'];
    if (content is Map) {
      final map = Map<String, dynamic>.from(content);
      final contentId =
          _readPostId(map['post_id'] ?? map['postId'] ?? map['id']);
      if (postId == null || contentId == null || contentId == postId) {
        final url = _readPreviewUrl(map);
        if (url != null) return url;
      }
    }

    return null;
  }

  static String? extractPostIdFromText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final viewPostMatch = _textPostIdRegex.firstMatch(trimmed);
    if (viewPostMatch != null) return _stripPst(viewPostMatch.group(1));

    if (_taggedPostTextRegex.hasMatch(trimmed)) {
      final taggedMatch = _taggedPostIdRegex.firstMatch(trimmed);
      if (taggedMatch != null) return _stripPst(taggedMatch.group(1));

      // Fallback for legacy / prefixed IDs
      return _stripPst(_barePostIdRegex.firstMatch(trimmed)?.group(1));
    }

    return null;
  }

  static bool isTaggedPostMessage(String text) {
    return _taggedPostTextRegex.hasMatch(text.trim());
  }

  /// User-visible caption stripped of the machine-readable post tag line.
  static String? companionText(String text, String postId) {
    var cleaned = text.trim();
    if (cleaned.isEmpty) return null;

    cleaned = cleaned.replaceAll(_taggedPostIdRegex, '').trim();
    cleaned = cleaned.replaceAll(_textPostIdRegex, '').trim();
    cleaned = cleaned.replaceAll(_taggedPostTextRegex, '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\b' + RegExp.escape(postId) + r'\b'), '').trim();
    cleaned = cleaned.replaceAll(RegExp('^${RegExp.escape(postId)}\$'), '').trim();
    cleaned = cleaned.replaceAll(_barePostIdRegex, '').trim();

    // Clean up any dangling colons or spaces
    cleaned = cleaned.replaceFirst(RegExp(r'^:\s*'), '').trim();
    cleaned = cleaned.replaceFirst(RegExp(r':\s*$'), '').trim();

    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  static String? _messageType(Map<String, dynamic> json) {
    return json['message_type']?.toString().toLowerCase() ??
        json['type']?.toString().toLowerCase();
  }

  static String? _readPostId(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return _stripPst(value);
  }

  static String? _stripPst(String? id) {
    if (id == null) return null;
    final trimmed = id.trim();
    if (trimmed.startsWith('pst_')) {
      return trimmed.substring(4);
    }
    return trimmed;
  }

  static String? _readPreviewUrl(Map<String, dynamic> map) {
    for (final key in _previewUrlKeys) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty && _looksLikeUrl(value)) {
        return value;
      }
    }

    for (final nestedKey in ['media', 'video', 'file']) {
      final nested = map[nestedKey];
      if (nested is! Map) continue;
      final nestedMap = Map<String, dynamic>.from(nested);
      for (final key in _previewUrlKeys) {
        final value = nestedMap[key]?.toString().trim();
        if (value != null && value.isNotEmpty && _looksLikeUrl(value)) {
          return value;
        }
      }
    }

    return null;
  }

  static bool _looksLikeUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  /// Short label for conversation list previews.
  static String conversationPreview(String text) {
    if (extractPostIdFromText(text) == null) return text;
    if (isTaggedPostMessage(text)) return 'Tagged you in a post';
    return 'Shared a post';
  }
}
