import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gruve_app/features/search/data/user_search/user_search_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class RecentSearchService {
  static const String _key = 'recent_searches';
  static const int _maxRecentSearches = 10;

  Future<void> addRecentSearch(SearchUser user) async {
    try {
      AppLogger.d('💾 [RecentSearchService] Adding user to recent searches: ${user.username}');
      
      final prefs = await SharedPreferences.getInstance();
      final recentSearches = await getRecentSearches();

      // Remove existing entry with same userId if exists
      recentSearches.removeWhere((existingUser) => existingUser.id == user.id);

      // Add to front of list
      recentSearches.insert(0, user);

      // Keep only max items
      if (recentSearches.length > _maxRecentSearches) {
        recentSearches.removeRange(_maxRecentSearches, recentSearches.length);
      }

      // Convert to JSON and save
      final jsonList = recentSearches.map((user) => _userToJson(user)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
      
      AppLogger.d('✅ [RecentSearchService] Added ${user.username}. Total recent searches: ${recentSearches.length}');
    } catch (e) {
      AppLogger.d('❌ [RecentSearchService] Error adding recent search: $e');
    }
  }

  Future<List<SearchUser>> getRecentSearches() async {
    try {
      AppLogger.d('📖 [RecentSearchService] Loading recent searches...');
      
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString == null || jsonString.isEmpty) {
        AppLogger.d('📖 [RecentSearchService] No recent searches found');
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final recentSearches = jsonList
          .whereType<Map<String, dynamic>>()
          .map((json) => _userFromJson(json))
          .whereType<SearchUser>()
          .toList();

      AppLogger.d('✅ [RecentSearchService] Loaded ${recentSearches.length} recent searches');
      return recentSearches;
    } catch (e) {
      AppLogger.d('❌ [RecentSearchService] Error loading recent searches: $e');
      return [];
    }
  }

  Future<void> removeRecentSearch(String userId) async {
    try {
      AppLogger.d('🗑️ [RecentSearchService] Removing user from recent searches: $userId');
      
      final recentSearches = await getRecentSearches();
      recentSearches.removeWhere((user) => user.id == userId);

      final prefs = await SharedPreferences.getInstance();
      final jsonList = recentSearches.map((user) => _userToJson(user)).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
      
      AppLogger.d('✅ [RecentSearchService] Removed user. Remaining: ${recentSearches.length}');
    } catch (e) {
      AppLogger.d('❌ [RecentSearchService] Error removing recent search: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      AppLogger.d('🗑️ [RecentSearchService] Clearing all recent searches...');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      
      AppLogger.d('✅ [RecentSearchService] Cleared all recent searches');
    } catch (e) {
      AppLogger.d('❌ [RecentSearchService] Error clearing recent searches: $e');
    }
  }

  Map<String, dynamic> _userToJson(SearchUser user) {
    return {
      'id': user.id,
      'name': user.name,
      'username': user.username,
      'avatar': user.avatar,
      'isOnline': user.isOnline,
    };
  }

  SearchUser? _userFromJson(Map<String, dynamic> json) {
    try {
      return SearchUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        avatar: json['avatar']?.toString() ?? '',
        isOnline: json['isOnline'] == true,
      );
    } catch (e) {
      AppLogger.d('⚠️ [RecentSearchService] Error parsing user from JSON: $e');
      return null;
    }
  }
}
