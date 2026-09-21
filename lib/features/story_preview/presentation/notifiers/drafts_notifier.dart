import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_draft_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

@immutable
class DraftsState {
  final List<PostDraft> drafts;
  final bool isLoading;
  final String? errorMessage;

  const DraftsState({
    this.drafts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DraftsState copyWith({
    List<PostDraft>? drafts,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DraftsState(
      drafts: drafts ?? this.drafts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DraftsNotifier extends Notifier<DraftsState> {
  final PostService _postService = PostService();

  @override
  DraftsState build() => const DraftsState();

  Future<void> fetchDrafts({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final response = await _postService.getDrafts(page: 1, limit: 50);
      AppLogger.d(
        "📦 [DraftsNotifier] Fetched ${response.results.length} drafts",
      );
      state = state.copyWith(drafts: response.results, clearError: true);
    } catch (e) {
      AppLogger.d("Error fetching drafts in provider: $e");
      state = state.copyWith(
        errorMessage: "Failed to load drafts. Please try again.",
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteDraft(String draftId) async {
    try {
      await _postService.deleteDraft(draftId);
      final updatedList = state.drafts
          .where((item) => item.id != draftId)
          .toList();
      state = state.copyWith(drafts: updatedList);
    } catch (e) {
      AppLogger.d("Error deleting draft in provider: $e");
      rethrow;
    }
  }

  Future<void> saveDraft({
    String? caption,
    String? mediaPath,
    String? mediaMimeType,
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
        mediaMimeType: mediaMimeType,
        locationName: locationName,
        audienceEveryone: audienceEveryone,
        audienceCloseFriends: audienceCloseFriends,
        scheduleReel: scheduleReel,
        uploadHighQuality: uploadHighQuality,
        hideLikeCount: hideLikeCount,
        hideShareCount: hideShareCount,
      );

      final dynamic rawData = responseMap['data'] ?? responseMap;
      if (rawData != null && rawData is Map) {
        final newDraft = PostDraft.fromJson(Map<String, dynamic>.from(rawData));
        if (newDraft.id.isNotEmpty) {
          state = state.copyWith(
            drafts: [
              newDraft,
              ...state.drafts.where((d) => d.id != newDraft.id),
            ],
          );
        }
      }
      // Silently sync latest from server
      await fetchDrafts(silent: true);
    } catch (e) {
      AppLogger.d("Error saving draft in provider: $e");
      rethrow;
    }
  }

  Future<void> updateDraft({
    required String draftId,
    String? caption,
    String? mediaPath,
    String? mediaMimeType,
    String? locationName,
    bool? audienceEveryone,
    bool? audienceCloseFriends,
    bool? scheduleReel,
    bool? uploadHighQuality,
    bool? hideLikeCount,
    bool? hideShareCount,
    bool clearMedia = false,
  }) async {
    AppLogger.d(
      "🔄 [DraftsNotifier] updateDraft - draftId: '$draftId', caption: '$caption'",
    );
    try {
      final responseMap = await _postService.updateDraft(
        draftId: draftId,
        caption: caption,
        mediaPath: mediaPath,
        mediaMimeType: mediaMimeType,
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
      AppLogger.d(
        "🔄 [DraftsNotifier] updateDraft API response rawData keys: ${rawData is Map ? rawData.keys : rawData.runtimeType}",
      );
      if (rawData != null) {
        final updatedDraft = PostDraft.fromJson(
          Map<String, dynamic>.from(rawData),
        );
        AppLogger.d(
          "🔄 [DraftsNotifier] parsed updatedDraft.id: '${updatedDraft.id}'",
        );
        final list = List<PostDraft>.from(state.drafts);
        final idx = list.indexWhere((d) => d.id == draftId);
        AppLogger.d(
          "🔄 [DraftsNotifier] index of original draft ID in local list: $idx",
        );
        if (idx != -1) {
          list[idx] = updatedDraft;
          AppLogger.d(
            "🔄 [DraftsNotifier] Updated local list draft at index $idx",
          );
        } else {
          list.insert(0, updatedDraft);
          AppLogger.d(
            "🔄 [DraftsNotifier] Inserted updatedDraft at index 0 because it was not in list",
          );
        }
        state = state.copyWith(drafts: list);
      }
    } catch (e) {
      AppLogger.d("Error updating draft in provider: $e");
      rethrow;
    }
  }

  void reset() {
    state = const DraftsState();
  }
}

final draftsNotifierProvider = NotifierProvider<DraftsNotifier, DraftsState>(
  DraftsNotifier.new,
);
