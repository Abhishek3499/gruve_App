import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';
import 'package:gruve_app/widgets/also_share_sheet.dart';
import 'package:provider/provider.dart';

class AppColors {
  static const sheetBackground = Color.fromARGB(238, 66, 19, 73);
  static const primaryPurple = Color(0xFF9B27AF);
  static const secondaryPurple = Color(0xFF6A0DAD);
  static const closeFriendsGreen = Color(0xFF00C27A);
  static const selectionPurple = Color(0xFF7B2FBE);
}

class StoryShareSheet extends StatefulWidget {
  final String? mediaPath;

  const StoryShareSheet({super.key, this.mediaPath});

  static void show(BuildContext context, {String? mediaPath}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return ChangeNotifierProvider.value(
          value: Provider.of<StoryController>(context, listen: false),
          child: StoryShareSheet(mediaPath: mediaPath),
        );
      },
    );
  }

  @override
  State<StoryShareSheet> createState() => _StoryShareSheetState();
}

class _StoryShareSheetState extends State<StoryShareSheet> {
  bool _yourStorySelected = true;
  bool _closeFriendsSelected = false;

  Future<void> _handleShareAction() async {
    if (!_yourStorySelected || widget.mediaPath == null) {
      Navigator.pop(context);
      return;
    }

    debugPrint('\n[StoryShareSheet] Share tapped');
    debugPrint('[StoryShareSheet] MediaPath: ${widget.mediaPath}');

    try {
      final storyController = Provider.of<StoryController>(
        context,
        listen: false,
      );

      await storyController.createStory(
        caption: '',
        mediaPath: widget.mediaPath!,
      );

      debugPrint('[StoryShareSheet] Response: ${storyController.message}');
      debugPrint('[StoryShareSheet] Success: ${storyController.isSuccess}');

      if (!mounted) return;

      if (storyController.isSuccess) {
        StoryStateController().markStoryAsShared(widget.mediaPath!);

        final navigator = Navigator.of(context);
        PostShareFlowBridge.notifyStorySharedNavigateToProfile();

        navigator.pop();
        if (navigator.canPop()) {
          navigator.pop();
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(storyController.message)),
        );
      }
    } catch (e) {
      debugPrint('[StoryShareSheet] Error: $e');

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while sharing story'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.sheetBackground,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            _ShareOptionTile(
              leading: const CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
              ),
              title: 'Your Story',
              subtitle: '@candice',
              trailing: _buildCheckCircle(_yourStorySelected),
              onTap: () =>
                  setState(() => _yourStorySelected = !_yourStorySelected),
            ),
            const SizedBox(height: 12),
            _ShareOptionTile(
              leading: _buildCircularIcon(
                Image.asset(AppAssets.stars, height: 25, width: 25),
                AppColors.closeFriendsGreen,
              ),
              title: 'Close Story',
              trailing: _buildCheckCircle(_closeFriendsSelected),
              onTap: () => setState(
                () => _closeFriendsSelected = !_closeFriendsSelected,
              ),
            ),
            const SizedBox(height: 12),
            _ShareOptionTile(
              leading: _buildCircularIcon(
                Image.asset(AppAssets.sendbutton, height: 26, width: 26),
                Colors.transparent,
                showBorder: true,
              ),
              title: 'Message',
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AlsoShareSheet(),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildGradientButton(text: 'Share', onPressed: _handleShareAction),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularIcon(
    Widget child,
    Color bgColor, {
    bool showBorder = false,
  }) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white38, width: 1.5)
            : null,
      ),
      child: Center(child: child),
    );
  }

  Widget _buildCheckCircle(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 26,
      width: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.selectionPurple : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.selectionPurple : Colors.white38,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.leading,
    required this.title,
    this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
