import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/profile/presentation/widgets/draft_tile.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_draft_model.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/drafts_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/screens/post/share_post_screen.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class ReelsDraftsScreen extends ConsumerStatefulWidget {
  const ReelsDraftsScreen({super.key});

  @override
  ConsumerState<ReelsDraftsScreen> createState() => _ReelsDraftsScreenState();
}

class _ReelsDraftsScreenState extends ConsumerState<ReelsDraftsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(draftsNotifierProvider.notifier).fetchDrafts();
      }
    });
  }

  void _editDraft(PostDraft draft) async {
    AppLogger.d(
      "📝 [ReelsDraftsScreen] Editing draft with ID: '${draft.id}', caption: '${draft.caption}', mediaUrl: '${draft.mediaUrl}'",
    );
    if (draft.mediaUrl == null || draft.mediaUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Draft has no media file associated."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharePostScreen(
          mediaPath: draft.mediaUrl!,
          draftId: draft.id,
          initialCaption: draft.caption,
          initialLocation: draft.locationName,
          initialIsEveryone: draft.audienceEveryone,
          initialIsCloseFriends: draft.audienceCloseFriends,
          initialScheduleReel: draft.scheduleReel,
          initialUploadHighQuality: draft.uploadHighQuality,
          initialHideLikeCount: draft.hideLikeCount,
          initialHideShareCount: draft.hideShareCount,
        ),
      ),
    );

    if (!mounted) return;
    // Refresh drafts list silently after returning from edit screen
    ref.read(draftsNotifierProvider.notifier).fetchDrafts(silent: true);
  }

  void _deleteDraft(PostDraft draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text(
            "Delete Draft",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to delete this draft?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFBB86FC)),
        ),
      );

      await ref.read(draftsNotifierProvider.notifier).deleteDraft(draft.id);

      if (!mounted) return;
      Navigator.pop(context); // Pop loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Draft deleted successfully."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Pop loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete draft: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftsState = ref.watch(draftsNotifierProvider);

    return Scaffold(
      // Dark Purple Gradient Background
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 73, 3, 87),
              Color.fromARGB(255, 14, 1, 16), // Near black bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Custom AppBar ---
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rw(16),
                  vertical: context.rh(20),
                ),
                child: Row(
                  children: [
                    BackButton(
                      color: Colors.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Reels Drafts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.rf(18),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () => ref
                          .read(draftsNotifierProvider.notifier)
                          .fetchDrafts(),
                    ),
                  ],
                ),
              ),

              // --- Draft List ---
              Expanded(child: _buildBody(draftsState)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(DraftsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFBB86FC)),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage!,
              style: TextStyle(color: Colors.white70, fontSize: context.rf(14)),
            ),
            SizedBox(height: context.rh(12)),
            ElevatedButton(
              onPressed: () =>
                  ref.read(draftsNotifierProvider.notifier).fetchDrafts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 120, 2, 99),
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final drafts = state.drafts;
    if (drafts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(draftsNotifierProvider.notifier).fetchDrafts(),
        color: const Color(0xFFBB86FC),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Text(
                  'No drafts saved yet',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: context.rf(16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(draftsNotifierProvider.notifier).fetchDrafts(),
      color: const Color(0xFFBB86FC),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: context.rw(16)),
        itemCount: drafts.length,
        itemBuilder: (context, index) {
          final draft = drafts[index];
          return DraftTile(
            draft: draft,
            onEdit: () => _editDraft(draft),
            onDelete: () => _deleteDraft(draft),
          );
        },
      ),
    );
  }
}
