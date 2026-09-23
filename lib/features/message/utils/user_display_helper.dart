import 'package:gruve_app/features/message/domain/entities/conversation_model.dart';
import 'package:gruve_app/features/message/domain/entities/user_entity.dart';
import 'package:gruve_app/features/user_profile/domain/entities/user_profile_model.dart';

/// Centralized user display utility to ensure consistent naming across the entire chat module
///
/// This helper ensures the EXACT same display name logic used on Profile Screen
/// is applied consistently across all chat module components.
///
/// DISPLAY NAME PRIORITY (matches Profile Screen):
/// 1. fullName (primary - same as profile screen)
/// 2. username (fallback)
/// 3. user ID (final fallback)
///
/// USAGE LOCATIONS:
/// - message avatar list
/// - conversation list
/// - chat header
/// - message tiles
/// - followers/following lists
///
/// NULL SAFETY:
/// - All methods handle null/empty values gracefully
///
/// Note: intentionally has no logging — these getters run on every list-item
/// build (e.g. once per avatar per rebuild), so logging here floods the
/// console on every unrelated rebuild (such as an online-status update).
class UserDisplayHelper {
  /// Get display name for UserEntity (from message avatar list)
  ///
  /// Uses the same priority logic as Profile Screen:
  /// fullName -> username -> user ID
  static String getDisplayNameForUserEntity(UserEntity user) {
    if (user.fullName.trim().isNotEmpty) {
      return user.fullName.trim();
    }

    if (user.username.trim().isNotEmpty) {
      return user.username.trim();
    }

    return 'User ${user.userId}';
  }

  /// Get display name for ConversationModel (from conversation list/chat header)
  ///
  /// Uses the same priority logic as Profile Screen:
  /// fullName -> username -> user ID
  static String getDisplayNameForConversation(ConversationModel conversation) {
    final name = conversation.otherUserName.trim();

    if (name.isNotEmpty && name != 'Unknown') {
      return name;
    }

    return 'User ${conversation.otherUser.id}';
  }

  /// Get display name for UserProfile (from profile screens)
  ///
  /// This matches exactly what Profile Screen displays
  static String getDisplayNameForUserProfile(UserProfile profile) {
    final name = profile.fullName.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return 'User ${profile.userId}';
  }

  /// Get display username with @ prefix (for Profile Screen style display)
  ///
  /// Matches Profile Screen's _displayUsername logic exactly
  static String getDisplayUsername(String? rawUsername) {
    final value = (rawUsername ?? '').trim();
    if (value.isEmpty) return '';
    return value.startsWith('@') ? value : '@$value';
  }

  /// Get display name for legacy dynamic user objects
  ///
  /// Handles various legacy user object formats with same priority logic
  static String getDisplayNameForLegacyUser(dynamic user) {
    if (user == null) {
      return 'Unknown User';
    }

    try {
      // Handle ConversationModel specifically
      if (user is ConversationModel) {
        final name = user.otherUserName.trim();
        if (name.isNotEmpty && name != 'Unknown') {
          return name;
        }
        return 'User ${user.otherUser.id}';
      }

      // Try fullName first (for UserEntity, UserProfile, etc.)
      final fullName = user.fullName?.toString().trim();
      if (fullName != null && fullName.isNotEmpty && fullName != 'Unknown') {
        return fullName;
      }

      // Try name field
      final name = user.name?.toString().trim();
      if (name != null && name.isNotEmpty && name != 'Unknown') {
        return name;
      }

      // Fallback to ID
      final id = user.id?.toString();
      return 'User ${id ?? 'Unknown'}';
    } catch (_) {
      return 'Unknown User';
    }
  }

  /// Get user ID safely from various user object types
  ///
  /// Centralized ID extraction with null safety
  static String getUserIdForUser(dynamic user) {
    if (user == null) {
      return '';
    }

    try {
      if (user is UserEntity) {
        return user.userId.trim();
      }

      if (user is ConversationModel) {
        return user.otherUser.id.trim();
      }

      if (user is UserProfile) {
        return user.userId.trim();
      }

      // Legacy dynamic user
      final id = user.id?.toString();
      if (id != null && id.isNotEmpty) {
        return id.trim();
      }

      return '';
    } catch (_) {
      return '';
    }
  }

  /// Get profile image URL safely from various user object types
  ///
  /// Centralized profile image extraction with null safety
  static String? getProfileImageForUser(dynamic user) {
    if (user == null) {
      return null;
    }

    try {
      if (user is UserEntity) {
        return user.profilePicture?.trim();
      }

      if (user is ConversationModel) {
        return user.otherUserAvatar?.trim();
      }

      if (user is UserProfile) {
        final pic = user.profilePicture.trim();
        return pic.isEmpty ? null : pic;
      }

      // Legacy dynamic user
      final avatar =
          user.avatar?.toString() ??
          user.profilePicture?.toString() ??
          user.profileImage?.toString();
      return avatar?.trim();
    } catch (_) {
      return null;
    }
  }

  /// Validate if a display name is valid and meaningful
  ///
  /// Used to filter out placeholder names
  static bool isValidDisplayName(String? name) {
    if (name == null) return false;

    final trimmed = name.trim();
    return trimmed.isNotEmpty &&
        trimmed.toLowerCase() != 'unknown' &&
        !trimmed.startsWith('User ') &&
        trimmed.length > 1;
  }
}
