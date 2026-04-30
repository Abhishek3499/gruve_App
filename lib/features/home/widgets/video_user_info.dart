import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/music_screen/music_screen.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/user_profile_screen.dart';

import '../controllers/subscribe_controller.dart';
import 'subscribe_button.dart';

class VideoUserInfo extends StatefulWidget {
  final String username;
  final String caption;
  final String musicTitle;
  final String userId;
  final int userCount;
  final String? profilePicture;
  final bool initialIsSubscribed;
  final bool hasActiveStory;
  final SubscribeController subscribeController;
  final VoidCallback onOwnProfileTap;

  const VideoUserInfo({
    super.key,
    required this.username,
    required this.caption,
    required this.musicTitle,
    required this.userId,
    this.userCount = 2,
    this.profilePicture,
    this.initialIsSubscribed = false,
    this.hasActiveStory = false,
    required this.subscribeController,
    required this.onOwnProfileTap,
  });

  @override
  State<VideoUserInfo> createState() => _VideoUserInfoState();
}

class _VideoUserInfoState extends State<VideoUserInfo> {
  ProfileIdentityResolution? _identityResolution;
  bool _isResolvingIdentity = true;

  @override
  void initState() {
    super.initState();
    _resolveProfileIdentity();
  }

  @override
  void didUpdateWidget(covariant VideoUserInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _resolveProfileIdentity();
    }
  }

  Future<void> _resolveProfileIdentity() async {
    setState(() {
      _isResolvingIdentity = true;
    });

    final resolution = await ProfileIdentityService.instance
        .resolveProfileIdentity(widget.userId);

    if (!mounted) {
      return;
    }

    setState(() {
      _identityResolution = resolution;
      _isResolvingIdentity = false;
    });
  }

  Future<void> _openProfile(BuildContext context) async {
    final resolution = _identityResolution ??
        await ProfileIdentityService.instance.resolveProfileIdentity(
          widget.userId,
        );

    if (!context.mounted) {
      return;
    }

    if (resolution.isOwnProfile) {
      widget.onOwnProfileTap();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          profileUserId: widget.userId,
          userName: widget.username,
          profileImageUrl: widget.profilePicture,
          initialHasActiveStory: widget.hasActiveStory,
        ),
      ),
    );
  }

  void _navigateToMusicScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicScreen(
          musicId: 'music_${widget.userId}',
          musicTitle: widget.musicTitle,
          musicUrl: 'https://example.com/music/${widget.userId}',
          userName: widget.username,
        ),
      ),
    );
  }

  String get displayUsername {
    if (widget.username.length <= 15) {
      return widget.username;
    }
    return '${widget.username.substring(0, 15)}...';
  }

  Widget _buildUsersPill() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person, color: Colors.white, size: 18),
              const SizedBox(width: 5),
              Text(
                '${widget.userCount} users',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    if (_isResolvingIdentity) {
      return const SizedBox(width: 96, height: 32);
    }

    if (!(_identityResolution?.shouldShowSubscribeButton ?? false)) {
      return const SizedBox.shrink();
    }

    // Hide button if already subscribed
    final isSubscribed = widget.subscribeController.isUserSubscribed(widget.userId);
    if (isSubscribed) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 32,
      child: SubscribeButton(
        userId: widget.userId,
        username: widget.username,
        initialIsSubscribed: widget.initialIsSubscribed,
        subscribeController: widget.subscribeController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _openProfile(context),
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  clipBehavior: Clip.antiAlias,
                  child:
                      (widget.profilePicture != null &&
                              widget.profilePicture!.isNotEmpty &&
                              widget.profilePicture!.startsWith('http'))
                          ? Image.network(
                              widget.profilePicture!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  AppAssets.user,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(AppAssets.user, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openProfile(context),
                  child: Text(
                    displayUsername,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              _buildSubscribeButton(),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.caption.isNotEmpty)
            Text(
              widget.caption,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  right: 120,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToMusicScreen(context),
                        child: Image.asset(
                          AppAssets.musicicon,
                          color: Colors.white,
                          height: 15,
                          width: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _navigateToMusicScreen(context),
                          child: Text(
                            widget.musicTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: -35,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _buildUsersPill()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
