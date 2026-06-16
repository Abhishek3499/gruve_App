import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/post_service.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_draft_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class DraftsProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  List<PostDraft> _drafts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PostDraft> get drafts => _drafts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDrafts({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _postService.getDrafts(page: 1, limit: 50);
      _drafts = response.results;
      _errorMessage = null;
    } catch (e) {
      AppLogger.d("Error fetching drafts in provider: $e");
      _errorMessage = "Failed to load drafts. Please try again.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDraft(String draftId) async {
    try {
      await _postService.deleteDraft(draftId);
      _drafts.removeWhere((item) => item.id == draftId);
      notifyListeners();
    } catch (e) {
      AppLogger.d("Error deleting draft in provider: $e");
      rethrow;
    }
  }

  Future<void> saveDraft({
    String? caption,
    String? mediaPath,
    String? locationName,
    bool audienceEveryone = true,
    bool audienceCloseFriends = false,
    bool scheduleReel = false,
    bool uploadHighQuality = false,
    bool hideLikeCount = false,
    bool hideShareCount = false,
  }) async {
    try {
      final responseMap = await _postService.saveDraft(
        caption: caption,
        mediaPath: mediaPath,
        locationName: locationName,
        audienceEveryone: audienceEveryone,
        audienceCloseFriends: audienceCloseFriends,
        scheduleReel: scheduleReel,
        uploadHighQuality: uploadHighQuality,
        hideLikeCount: hideLikeCount,
        hideShareCount: hideShareCount,
      );

      final dynamic rawData = responseMap['data'] ?? responseMap;
      if (rawData != null) {
        final newDraft = PostDraft.fromJson(Map<String, dynamic>.from(rawData));
        _drafts.insert(0, newDraft);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.d("Error saving draft in provider: $e");
      rethrow;
    }
  }

  Future<void> updateDraft({
    required String draftId,
    String? caption,
    String? mediaPath,
    String? locationName,
    bool? audienceEveryone,
    bool? audienceCloseFriends,
    bool? scheduleReel,
    bool? uploadHighQuality,
    bool? hideLikeCount,
    bool? hideShareCount,
    bool clearMedia = false,
  }) async {
    try {
      final responseMap = await _postService.updateDraft(
        draftId: draftId,
        caption: caption,
        mediaPath: mediaPath,
        locationName: locationName,
        audienceEveryone: audienceEveryone,
        audienceCloseFriends: audienceCloseFriends,
        scheduleReel: scheduleReel,
        uploadHighQuality: uploadHighQuality,
        hideLikeCount: hideLikeCount,
        hideShareCount: hideShareCount,
        clearMedia: clearMedia,
      );

      final dynamic rawData = responseMap['data'] ?? responseMap;
      if (rawData != null) {
        final updatedDraft = PostDraft.fromJson(Map<String, dynamic>.from(rawData));
        final idx = _drafts.indexWhere((d) => d.id == draftId);
        if (idx != -1) {
          _drafts[idx] = updatedDraft;
        } else {
          _drafts.insert(0, updatedDraft);
        }
        notifyListeners();
      }
    } catch (e) {
      AppLogger.d("Error updating draft in provider: $e");
      rethrow;
    }
  }

  void reset() {
    _drafts = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
