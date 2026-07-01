import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/profile/widgets/draft_tile.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_draft_model.dart';
import 'package:gruve_app/features/story_preview/providers/drafts_provider.dart';
import 'package:gruve_app/features/story_preview/screens/post/share_post_screen.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ReelsDraftsScreen extends StatefulWidget {
  const ReelsDraftsScreen({super.key});

  @override
  State<ReelsDraftsScreen> createState() => _ReelsDraftsScreenState();
}

class _ReelsDraftsScreenState extends State<ReelsDraftsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DraftsProvider>().fetchDrafts();
      }
    });
  }

  void _editDraft(PostDraft draft) async {
    AppLogger.d("📝 [ReelsDraftsScreen] Editing draft with ID: '${draft.id}', caption: '${draft.caption}', mediaUrl: '${draft.mediaUrl}'");
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
    context.read<DraftsProvider>().fetchDrafts(silent: true);
  }

  void _deleteDraft(PostDraft draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E092D),
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
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
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

      await context.read<DraftsProvider>().deleteDraft(draft.id);

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
    final draftsProvider = context.watch<DraftsProvider>();

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    BackButton(
                      color: Colors.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Reels Drafts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () => context.read<DraftsProvider>().fetchDrafts(),
                    ),
                  ],
                ),
              ),

              // --- Draft List ---
              Expanded(
                child: _buildBody(draftsProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(DraftsProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFBB86FC)),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.fetchDrafts(),
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

    final drafts = provider.drafts;
    if (drafts.isEmpty) {
      return const Center(
        child: Text(
          'No drafts saved yet',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: drafts.length,
      itemBuilder: (context, index) {
        final draft = drafts[index];
        return DraftTile(
          draft: draft,
          onEdit: () => _editDraft(draft),
          onDelete: () => _deleteDraft(draft),
        );
      },
    );
  }
}
