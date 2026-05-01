import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/screens/auth/api/controllers/logout_controller.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/highlights/provider/highlight_flow_provider.dart';
import 'package:gruve_app/features/user_profile/providers/block_provider.dart';
import 'package:gruve_app/features/story_preview/providers/save_post_provider.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';

class LogoutProvider extends ChangeNotifier {
  final LogoutController _controller = LogoutController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _shouldNavigate = false;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get shouldNavigate => _shouldNavigate;

  /// Main logout method with complete state reset
  Future<void> logout({BuildContext? context}) async {
    debugPrint('🔥 [LogoutProvider] Starting complete logout process...');
    
    // Set loading state immediately
    _setLoading(true);
    _errorMessage = null;

    try {
      // Step 1: Reset all providers BEFORE any async operations if context is available
      if (context != null) {
        await _resetAllProviders(context);
      }
      
      // Step 2: Execute logout API call
      await _controller.logout();
      debugPrint('🔥 [LogoutProvider] Logout API completed');
      
      // Step 3: Check for API errors
      if (_controller.errorMessage != null) {
        _errorMessage = _controller.errorMessage;
        debugPrint('❌ [LogoutProvider] Logout API failed: $_errorMessage');
        return;
      }
      
      debugPrint('✅ [LogoutProvider] Logout API successful');
      
      // Step 4: Clear all storage (this happens in LogoutController too, but ensure it's complete)
      await _clearAllStorage();
      
      debugPrint('✅ [LogoutProvider] Complete logout successful');
      
      // Trigger navigation to sign-in screen
      _shouldNavigate = true;
      notifyListeners();
      
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ [LogoutProvider] Logout exception: $e');
    } finally {
      // Clear loading state
      _setLoading(false);
    }
  }

  /// Reset all providers to clear user data
  Future<void> _resetAllProviders(BuildContext context) async {
    debugPrint('🔄 [LogoutProvider] Resetting all providers...');
    
    try {
      // Store all provider references before async operations
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final storyController = Provider.of<StoryController>(context, listen: false);
      final highlightProvider = Provider.of<HighlightFlowProvider>(context, listen: false);
      final blockProvider = Provider.of<BlockProvider>(context, listen: false);
      final saveProvider = Provider.of<SavePostProvider>(context, listen: false);
      
      // Reset ProfileProvider
      profileProvider.reset();
      
      // Reset StoryController
      storyController.reset();
      
      // Reset HighlightFlowProvider
      highlightProvider.reset();
      
      // Reset BlockProvider
      blockProvider.reset();
      
      // Reset SavePostProvider
      saveProvider.reset();
      
      debugPrint('✅ [LogoutProvider] All providers reset successfully');
    } catch (e) {
      debugPrint('❌ [LogoutProvider] Error resetting providers: $e');
    }
  }

  /// Clear all storage completely
  Future<void> _clearAllStorage() async {
    debugPrint('🗑️ [LogoutProvider] Clearing all storage...');
    
    try {
      // Clear tokens (already done in LogoutController, but ensure it's complete)
      await TokenStorage.clearTokens();
      
      // Clear reset token if exists
      await TokenStorage.clearResetToken();
      
      debugPrint('✅ [LogoutProvider] All storage cleared successfully');
    } catch (e) {
      debugPrint('❌ [LogoutProvider] Error clearing storage: $e');
    }
  }

  /// Clear any error messages
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Reset navigation flag after navigation is handled
  void resetNavigationFlag() {
    if (_shouldNavigate) {
      _shouldNavigate = false;
      debugPrint('🔄 [LogoutProvider] Navigation flag reset');
      notifyListeners();
    }
  }

  /// Internal method to update loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      debugPrint('🔄 [LogoutProvider] Loading: $loading');
      notifyListeners();
    }
  }
}
