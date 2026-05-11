import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../presentation/provider/user_provider.dart';
import '../domain/entities/user_entity.dart';
import '../../profile/data/models/user_profile_model.dart';

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
/// - Comprehensive debug logging for troubleshooting
/// - Production-level error handling
class UserDisplayHelper {
  /// Get display name for UserEntity (from message avatar list)
  /// 
  /// Uses the same priority logic as Profile Screen:
  /// fullName -> username -> user ID
  static String getDisplayNameForUserEntity(UserEntity user) {
    if (user.fullName.trim().isNotEmpty) {
      debugPrint('👤 [UserDisplayHelper] UserEntity displayName: "${user.fullName}" (using fullName)');
      return user.fullName.trim();
    }
    
    if (user.username.trim().isNotEmpty) {
      debugPrint('👤 [UserDisplayHelper] UserEntity displayName: "${user.username}" (using username fallback)');
      return user.username.trim();
    }
    
    final fallback = 'User ${user.userId}';
    debugPrint('👤 [UserDisplayHelper] UserEntity displayName: "$fallback" (using ID fallback)');
    return fallback;
  }

  /// Get display name for ConversationModel (from conversation list/chat header)
  /// 
  /// Uses the same priority logic as Profile Screen:
  /// fullName -> username -> user ID
  static String getDisplayNameForConversation(ConversationModel conversation) {
    final name = conversation.otherUserName.trim();
    
    if (name.isNotEmpty && name != 'Unknown') {
      debugPrint('👤 [UserDisplayHelper] Conversation displayName: "$name" (using otherUserName)');
      return name;
    }
    
    final fallback = 'User ${conversation.otherUser.id}';
    debugPrint('👤 [UserDisplayHelper] Conversation displayName: "$fallback" (using ID fallback)');
    return fallback;
  }

  /// Get display name for UserProfile (from profile screens)
  /// 
  /// This matches exactly what Profile Screen displays
  static String getDisplayNameForUserProfile(UserProfile profile) {
    final name = profile.fullName.trim();
    
    if (name.isNotEmpty) {
      debugPrint('👤 [UserDisplayHelper] UserProfile displayName: "$name" (using fullName)');
      return name;
    }
    
    final fallback = 'User ${profile.userId ?? 'Unknown'}';
    debugPrint('👤 [UserDisplayHelper] UserProfile displayName: "$fallback" (using ID fallback)');
    return fallback;
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
    try {
      debugPrint('🔍 [UserDisplayHelper] Processing legacy user: ${user.runtimeType}');
      
      // Handle ConversationModel specifically
      if (user is ConversationModel) {
        final name = user.otherUserName.trim();
        if (name.isNotEmpty && name != 'Unknown') {
          debugPrint('👤 [UserDisplayHelper] ConversationModel displayName: "$name" (using otherUserName)');
          return name;
        }
        final fallback = 'User ${user.otherUser.id}';
        debugPrint('👤 [UserDisplayHelper] ConversationModel displayName: "$fallback" (using ID fallback)');
        return fallback;
      }
      
      // Try fullName first (for UserEntity, UserProfile, etc.)
      final fullName = user.fullName?.toString().trim() ?? '';
      if (fullName.isNotEmpty && fullName != 'Unknown') {
        debugPrint('👤 [UserDisplayHelper] LegacyUser displayName: "$fullName" (using fullName)');
        return fullName;
      }
      
      // Try name field
      final name = user.name?.toString().trim() ?? '';
      if (name.isNotEmpty && name != 'Unknown') {
        debugPrint('👤 [UserDisplayHelper] LegacyUser displayName: "$name" (using name)');
        return name;
      }
      
      // Fallback to ID
      final id = user.id?.toString() ?? 'Unknown';
      final fallback = 'User $id';
      debugPrint('👤 [UserDisplayHelper] LegacyUser displayName: "$fallback" (using ID fallback)');
      return fallback;
    } catch (e) {
      debugPrint('❌ [UserDisplayHelper] Error getting legacy user display name: $e');
      return 'Unknown User';
    }
  }

  /// Get user ID safely from various user object types
  /// 
  /// Centralized ID extraction with null safety
  static String getUserIdForUser(dynamic user) {
    try {
      if (user is UserEntity) {
        return user.userId.trim();
      }
      
      if (user is ConversationModel) {
        return user.otherUser.id.trim();
      }
      
      if (user is UserProfile) {
        return (user.userId ?? '').trim();
      }
      
      // Legacy dynamic user
      final id = user.id?.toString() ?? user.userId?.toString() ?? '';
      if (id.isNotEmpty) {
        return id.trim();
      }
      
      debugPrint('⚠️ [UserDisplayHelper] Could not extract user ID from: ${user.runtimeType}');
      return '';
    } catch (e) {
      debugPrint('❌ [UserDisplayHelper] Error extracting user ID: $e');
      return '';
    }
  }

  /// Get profile image URL safely from various user object types
  /// 
  /// Centralized profile image extraction with null safety
  static String? getProfileImageForUser(dynamic user) {
    try {
      if (user is UserEntity) {
        return user.profilePicture?.trim();
      }
      
      if (user is ConversationModel) {
        return user.otherUserAvatar?.trim();
      }
      
      if (user is UserProfile) {
        return user.profilePicture?.trim();
      }
      
      // Legacy dynamic user
      final avatar = user.avatar?.toString() ?? 
                   user.profilePicture?.toString() ?? 
                   user.profileImage?.toString();
      return avatar?.trim();
    } catch (e) {
      debugPrint('❌ [UserDisplayHelper] Error extracting profile image: $e');
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
