import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/features/profile/data/datasource/edit_profile_service.dart';
import 'package:gruve_app/features/home/presentation/controllers/post_share_flow_bridge.dart';
import 'package:gruve_app/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_controller_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_state_notifier.dart';
import 'package:gruve_app/features/story_preview/presentation/screens/close_friend_screen.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/also_share_sheet.dart';
import 'package:gruve_app/features/search/data/datasource/user_search_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class StoryShareColors {
  static const sheetBackground = Color.fromARGB(238, 66, 19, 73);
  static const primaryPurple = Color(0xFF9B27AF);
  static const secondaryPurple = Color(0xFF6A0DAD);
  static const closeFriendsGreen = Color(0xFF00C27A);
  static const selectionPurple = Color(0xFF7B2FBE);
}

class _StoryShareProfile {
  final String username;
  final String profileImage;

  const _StoryShareProfile({
    required this.username,
    required this.profileImage,
  });
}

class StoryShareSheet extends ConsumerStatefulWidget {
  final String? mediaPath;
  final bool isMuted;

  const StoryShareSheet({super.key, this.mediaPath, this.isMuted = false});

  static void show(
    BuildContext context, {
    String? mediaPath,
    bool isMuted = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StoryShareSheet(mediaPath: mediaPath, isMuted: isMuted);
      },
    );
  }

  @override
  ConsumerState<StoryShareSheet> createState() => _StoryShareSheetState();
}

class _StoryShareSheetState extends ConsumerState<StoryShareSheet> {
  bool _yourStorySelected = true;
  bool _closeFriendsSelected = false;
  Set<String> _selectedCloseFriendIds = {};
  bool _isLoading = false;
  bool _isProfileLoading = false;
  _StoryShareProfile? _profile;
  String? _errorMessage;

  static _StoryShareProfile? _cachedProfile;
  static Future<_StoryShareProfile?>? _profileRequest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureOwnProfileLoaded();
    });
  }

  void _ensureOwnProfileLoaded() {
    if (!mounted) return;

    final providerUser = ref.read(profileNotifierProvider).user;
    if (providerUser != null) {
      setState(() {
        _profile = _StoryShareProfile(
          username: providerUser.username,
          profileImage: providerUser.profileImage,
        );
      });
      return;
    }

    final cached = _cachedProfile;
    if (cached != null) {
      setState(() => _profile = cached);
      return;
    }

    if (_profileRequest != null) {
      _awaitProfileRequest(_profileRequest!);
      return;
    }

    setState(() => _isProfileLoading = true);
    final request = _fetchOwnProfileForShareSheet();
    _profileRequest = request;
    _awaitProfileRequest(request);
  }

  Future<void> _awaitProfileRequest(Future<_StoryShareProfile?> request) async {
    final profile = await request;
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _isProfileLoading = false;
    });
  }

  Future<_StoryShareProfile?> _fetchOwnProfileForShareSheet() async {
    try {
      final response = await EditProfileService().fetchProfile().timeout(
        const Duration(seconds: 5),
      );

      final profile = _StoryShareProfile(
        username: response.data.username,
        profileImage: response.data.profilePicture ?? '',
      );

      _cachedProfile = profile;
      return profile;
    } catch (e) {
      AppLogger.d('[StoryShareSheet] Own profile load skipped: $e');
      return null;
    } finally {
      _profileRequest = null;
    }
  }

  Future<void> _openCloseFriendsPicker() async {
    // Choosing this destination selects it immediately, mutually exclusive
    // with "Your Story" — independent of whether any friends get picked.
    setState(() {
      _closeFriendsSelected = true;
      _yourStorySelected = false;
    });

    final result = await Navigator.push<List<SearchUser>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CloseFriendScreen(initialSelectedUserIds: _selectedCloseFriendIds),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedCloseFriendIds = result.map((user) => user.id).toSet();
    });
  }

  Future<void> _handleShareAction() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    if (!_yourStorySelected && !_closeFriendsSelected) {
      setState(() {
        _errorMessage = 'Please select at least one destination to share.';
      });
      return;
    }

    if (widget.mediaPath == null) {
      setState(() {
        _errorMessage = 'No media selected to share.';
      });
      return;
    }

    AppLogger.d('\n[StoryShareSheet] Share tapped');
    AppLogger.d('[StoryShareSheet] MediaPath: ${widget.mediaPath}');

    setState(() {
      _isLoading = true;
    });

    try {
      final storyController = ref.read(storyControllerProvider.notifier);

      await storyController.createStory(
        caption: '',
        mediaPath: widget.mediaPath!,
        isMuted: widget.isMuted,
      );

      AppLogger.d('[StoryShareSheet] Response: ${storyController.message}');
      AppLogger.d('[StoryShareSheet] Success: ${storyController.isSuccess}');

      if (!mounted) return;

      if (storyController.isSuccess) {
        ref
            .read(storyStateNotifierProvider.notifier)
            .markStoryAsShared(widget.mediaPath!);

        final navigator = Navigator.of(context);
        PostShareFlowBridge.notifyStorySharedNavigateToProfile();

        navigator.popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = storyController.message;
        });
      }
    } catch (e) {
      AppLogger.d('[StoryShareSheet] Error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong while sharing story';
      });
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
          color: StoryShareColors.sheetBackground,
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
              leading: _buildOwnProfileAvatar(
                imageUrl: _profile?.profileImage,
                username: _profile?.username ?? '',
                isLoading: _isProfileLoading,
              ),
              title: 'Your Story',
              subtitle: (_profile?.username.trim().isNotEmpty ?? false)
                  ? '@${_profile!.username.trim()}'
                  : null,
              trailing: _buildCheckCircle(_yourStorySelected),
              onTap: () => setState(() {
                _yourStorySelected = !_yourStorySelected;
                if (_yourStorySelected) {
                  _closeFriendsSelected = false;
                  _selectedCloseFriendIds = {};
                }
              }),
            ),
            const SizedBox(height: 12),
            _ShareOptionTile(
              leading: _buildCircularIcon(
                Image.asset(AppAssets.stars, height: 25, width: 25),
                StoryShareColors.closeFriendsGreen,
              ),
              title: 'Close Story',
              subtitle: _selectedCloseFriendIds.isNotEmpty
                  ? '${_selectedCloseFriendIds.length} friend${_selectedCloseFriendIds.length == 1 ? '' : 's'}'
                  : null,
              trailing: _buildCheckCircle(_closeFriendsSelected),
              onTap: _openCloseFriendsPicker,
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
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildGradientButton(
              text: _isLoading ? 'Sharing...' : 'Share',
              onPressed: _isLoading ? null : _handleShareAction,
              isLoading: _isLoading,
            ),
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

  Widget _buildOwnProfileAvatar({
    required String? imageUrl,
    required String username,
    required bool isLoading,
  }) {
    final trimmedImageUrl = imageUrl?.trim() ?? '';

    if (isLoading && trimmedImageUrl.isEmpty) {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white12,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: Colors.white70,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (trimmedImageUrl.startsWith('http')) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white12,
        backgroundImage: NetworkImage(trimmedImageUrl),
      );
    }

    final fallbackLetter = username.isNotEmpty ? username[0].toUpperCase() : '';

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.white12,
      backgroundImage: fallbackLetter.isEmpty
          ? const AssetImage(AppAssets.profile)
          : null,
      child: fallbackLetter.isEmpty
          ? null
          : Text(
              fallbackLetter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  Widget _buildCheckCircle(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 26,
      width: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? StoryShareColors.selectionPurple : Colors.transparent,
        border: Border.all(
          color: selected ? StoryShareColors.selectionPurple : Colors.white38,
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
    required VoidCallback? onPressed,
    bool isLoading = false,
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
            gradient: onPressed != null
                ? const LinearGradient(
                    colors: [
                      StoryShareColors.primaryPurple,
                      StoryShareColors.secondaryPurple,
                    ],
                  )
                : LinearGradient(
                    colors: [
                      StoryShareColors.primaryPurple.withValues(alpha: 0.5),
                      StoryShareColors.secondaryPurple.withValues(alpha: 0.5),
                    ],
                  ),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Sharing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Text(
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
