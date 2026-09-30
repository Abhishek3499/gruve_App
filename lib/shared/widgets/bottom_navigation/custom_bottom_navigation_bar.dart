import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/constants/app_assets.dart';
import 'package:gruve_app/core/auth/current_user_notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gruve_app/shared/widgets/bottom_navigation/nav_item.dart';
import 'package:gruve_app/shared/widgets/bottom_navigation/nav_bar_clipper.dart';
import 'package:gruve_app/shared/widgets/bottom_navigation/center_nav_button.dart';

class CustomBottomNavigationBar extends ConsumerStatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  ConsumerState<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState
    extends ConsumerState<CustomBottomNavigationBar> {
  // Minimum breathing room above the screen edge even if a device briefly
  // reports a zero bottom inset (e.g. mid rotation, or a manufacturer quirk).
  static const double _minBottomGap = 2;

  bool _profilePressed = false;

  void _setProfilePressed(bool value) {
    if (_profilePressed != value) setState(() => _profilePressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: SizedBox(
        height: 60 + bottomInset,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // NAVBAR with CustomPaint — the background is allowed to bleed
            // into the system gesture/nav bar area for an edge-to-edge look,
            // while the interactive content below is kept clear of it via
            // SafeArea.
            Positioned(
              bottom: -2,
              left: 0,
              right: 0,
              child: CustomPaint(
                painter: NavBarPainter(),
                child: SizedBox(
                  height: 54 + bottomInset,
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    minimum: const EdgeInsets.only(bottom: _minBottomGap),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          NavItem(
                            imagePath: AppAssets.navHome,
                            index: 0,
                            selectedIndex: widget.selectedIndex,
                            onTap: () => widget.onItemSelected(0),
                          ),
                          NavItem(
                            imagePath: AppAssets.navSearch,
                            index: 1,
                            selectedIndex: widget.selectedIndex,
                            onTap: () => widget.onItemSelected(1),
                          ),
                          const SizedBox(width: 38),
                          NavItem(
                            imagePath: AppAssets.navMessage,
                            index: 3,
                            selectedIndex: widget.selectedIndex,
                            onTap: () => widget.onItemSelected(3),
                          ),
                          _buildProfileNavItem(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // CENTER BUTTON
            Positioned(
              top: 13,
              child: CenterNavButton(
                isSelected: widget.selectedIndex == 2,
                onTap: () => widget.onItemSelected(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(BuildContext context) {
    final profileImageUrl = ref.watch(
      currentUserNotifierProvider.select((s) => s.profileImageUrl),
    );
    final isActive = widget.selectedIndex == 4;

    return GestureDetector(
      onTap: () => widget.onItemSelected(4),
      onTapDown: (_) => _setProfilePressed(true),
      onTapUp: (_) => _setProfilePressed(false),
      onTapCancel: () => _setProfilePressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _profilePressed ? 0.82 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// PROFILE IMAGE with height translation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(0, isActive ? -3.5 : 0, 0),
              child: Container(
                width: isActive ? 24 : 22,
                height: isActive ? 24 : 22,
                padding: isActive ? const EdgeInsets.all(1.0) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: Colors.white, width: 1.2)
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                ),
                child: ClipOval(
                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: profileImageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildShimmerPlaceholder(),
                          errorWidget: (context, url, error) =>
                              _buildDefaultProfileIcon(),
                        )
                      : _buildDefaultProfileIcon(),
                ),
              ),
            ),

            const SizedBox(height: 2),

            /// WHITE DOT with scale and position animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform:
                  Matrix4.translationValues(0.0, isActive ? -5.0 : -2.5, 0.0)
                    ..multiply(
                      Matrix4.diagonal3Values(
                        isActive ? 1.2 : 1.0,
                        isActive ? 1.2 : 1.0,
                        1.0,
                      ),
                    ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isActive ? 1 : 0,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown in place of the avatar when the user has no profile picture set
  /// (or it fails to load).
  Widget _buildDefaultProfileIcon() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Image.asset(AppAssets.navProfile, color: Colors.white),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.1),
      highlightColor: Colors.white.withValues(alpha: 0.2),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
