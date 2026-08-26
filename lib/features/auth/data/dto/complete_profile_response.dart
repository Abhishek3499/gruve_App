class CompleteProfileResponse {
  final bool success;
  final String message;

  CompleteProfileResponse({required this.success, required this.message});

  static bool _coerceSuccess(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes' || s == 'success';
    }
    return false;
  }

  static String _coerceMessage(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  /// Picks a human-readable message from common API error shapes.
  static String _extractMessage(Map<String, dynamic> map) {
    for (final key in ['message', 'detail', 'error', 'msg']) {
      final v = map[key];
      if (v == null) continue;
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is List && v.isNotEmpty) return v.first.toString();
      if (v is Map) return v.toString();
    }
    return '';
  }

  factory CompleteProfileResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> root = Map<String, dynamic>.from(json);

    if (json['data'] is Map) {
      final inner = Map<String, dynamic>.from(json['data'] as Map);
      inner.forEach((k, v) {
        root.putIfAbsent(k, () => v);
      });
    }

    final explicitSuccess = root.containsKey('success')
        ? _coerceSuccess(root['success'])
        : null;

    final statusStr = root['status'];
    final statusOk = statusStr is String &&
        statusStr.toLowerCase().trim() == 'success';

    // After merging `data`, profile fields often live as user_id / username / profile_picture.
    final hasUserPayload = root['user'] != null ||
        root['profile'] != null ||
        root['id'] != null ||
        root['user_id'] != null;

    final errors = root['errors'] ?? root['non_field_errors'];
    final hasErrors = errors != null &&
        ((errors is Map && errors.isNotEmpty) ||
            (errors is List && errors.isNotEmpty));

    final code = root['code'];
    final codeOk = code == 200 ||
        code == '200' ||
        (code is num && code.toInt() == 200);

    // Many backends return 200 with `{ "user": ... }` or `{}` without `success`.
    final inferredOk = explicitSuccess == null &&
        !hasErrors &&
        (root['error'] == null || root['error'] == false) &&
        (hasUserPayload || root.isEmpty || codeOk);

    final success = explicitSuccess == true ||
        (explicitSuccess == null && statusOk) ||
        (explicitSuccess == null && codeOk && hasUserPayload && !hasErrors) ||
        inferredOk;

    final extracted = _extractMessage(root);
    final message = extracted.isNotEmpty
        ? extracted
        : _coerceMessage(root['message']);

    return CompleteProfileResponse(
      success: success,
      message: message,
    );
  }
}
