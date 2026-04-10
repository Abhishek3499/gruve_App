import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class ProfileIdentityResolution {
  final String? loggedInUserId;
  final String? profileUserId;

  const ProfileIdentityResolution({
    required this.loggedInUserId,
    required this.profileUserId,
  });

  bool get hasLoggedInUserId => _hasValue(loggedInUserId);
  bool get hasProfileUserId => _hasValue(profileUserId);

  bool get isOwnProfile =>
      hasLoggedInUserId &&
      hasProfileUserId &&
      loggedInUserId!.trim() == profileUserId!.trim();

  bool get shouldShowSubscribeButton => hasProfileUserId && !isOwnProfile;

  static bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}

class ProfileIdentityService {
  ProfileIdentityService._();

  static final ProfileIdentityService instance = ProfileIdentityService._();

  String? _cachedLoggedInUserId;
  bool _hasResolvedLoggedInUser = false;

  Future<String?> getLoggedInUserId() async {
    if (_hasResolvedLoggedInUser) {
      return _cachedLoggedInUserId;
    }

    final storedUserId = await TokenStorage.getCurrentUserId();
    if (_isValidUserId(storedUserId)) {
      _cachedLoggedInUserId = storedUserId!.trim();
      _hasResolvedLoggedInUser = true;
      return _cachedLoggedInUserId;
    }

    final accessToken = await TokenStorage.getAccessToken();
    final decodedUserId = _extractUserIdFromToken(accessToken);

    if (_isValidUserId(decodedUserId)) {
      _cachedLoggedInUserId = decodedUserId!.trim();
      _hasResolvedLoggedInUser = true;
      await TokenStorage.saveCurrentUserId(_cachedLoggedInUserId!);
      return _cachedLoggedInUserId;
    }

    _cachedLoggedInUserId = null;
    _hasResolvedLoggedInUser = true;
    return null;
  }

  Future<ProfileIdentityResolution> resolveProfileIdentity(
    String? profileUserId,
  ) async {
    final loggedInUserId = await getLoggedInUserId();
    final normalizedProfileUserId = _normalizeUserId(profileUserId);

    final resolution = ProfileIdentityResolution(
      loggedInUserId: _normalizeUserId(loggedInUserId),
      profileUserId: normalizedProfileUserId,
    );

    debugPrint('👤 LoggedInUserId: ${resolution.loggedInUserId ?? "null"}');
    debugPrint('📄 ProfileUserId: ${resolution.profileUserId ?? "null"}');
    debugPrint('🔍 IsOwnProfile: ${resolution.isOwnProfile}');

    return resolution;
  }

  void primeLoggedInUserId(String? userId) {
    final normalizedUserId = _normalizeUserId(userId);
    _cachedLoggedInUserId = normalizedUserId;
    _hasResolvedLoggedInUser = true;
  }

  void clearCachedLoggedInUserId() {
    _cachedLoggedInUserId = null;
    _hasResolvedLoggedInUser = false;
  }

  String? _extractUserIdFromToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return _readUserIdFromClaims(decoded);
    } catch (error) {
      debugPrint('❌ Failed to decode access token user id: $error');
      return null;
    }
  }

  String? _readUserIdFromClaims(Map<String, dynamic> claims) {
    final directCandidates = [
      claims['user_id'],
      claims['userId'],
      claims['id'],
      claims['sub'],
      claims['uid'],
    ];

    for (final candidate in directCandidates) {
      final normalized = _normalizeDynamicUserId(candidate);
      if (normalized != null) {
        return normalized;
      }
    }

    final nestedUser = claims['user'];
    if (nestedUser is Map<String, dynamic>) {
      final nestedCandidates = [
        nestedUser['id'],
        nestedUser['user_id'],
        nestedUser['userId'],
      ];

      for (final candidate in nestedCandidates) {
        final normalized = _normalizeDynamicUserId(candidate);
        if (normalized != null) {
          return normalized;
        }
      }
    }

    return null;
  }

  String? _normalizeDynamicUserId(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      return _normalizeUserId(value);
    }

    if (value is num) {
      return value.toString();
    }

    return null;
  }

  bool _isValidUserId(String? value) => _normalizeUserId(value) != null;

  String? _normalizeUserId(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
