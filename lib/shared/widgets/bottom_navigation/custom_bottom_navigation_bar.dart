import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/auth/current_user_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gruve_app/shared/widgets/bottom_navigation/nav_item.dart';
import 'package:gruve_app/shared/widgets/bottom_navigation/nav_bar_clipper.dart';
import 'package:gruve_app/shared/widgets/bottom_navigation/center_nav_button.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    return SizedBox(
      height: 100 + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // NAVBAR with CustomPaint
          Positioned(
            bottom: -2,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: NavBarPainter(),
              child: SizedBox(
                height: 80 + bottomPadding,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 28,
                    bottom: bottomPadding,
                  ), // icons neeche push karo, bottom padding handles gesture bar
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      NavItem(
                        imagePath: AppAssets.homelogo,
                        index: 0,
                        selectedIndex: widget.selectedIndex,
                        onTap: () => widget.onItemSelected(0),
                      ),
                      NavItem(
                        imagePath: AppAssets.search,
                        index: 1,
                        selectedIndex: widget.selectedIndex,
                        onTap: () => widget.onItemSelected(1),
                      ),
                      const SizedBox(width: 55),
                      NavItem(
                        imagePath: AppAssets.notification,
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

          // CENTER BUTTON
          Positioned(
            top: 32,
            child: CenterNavButton(
              isSelected: widget.selectedIndex == 2,
              onTap: () => widget.onItemSelected(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileNavItem(BuildContext context) {
    return Consumer<CurrentUserProvider>(
      builder: (context, userProvider, _) {
        final profileImageUrl = userProvider.profileImageUrl;
        final username = userProvider.username;
        final isActive = widget.selectedIndex == 4;
        final initials = _getInitials(username);

        return GestureDetector(
          onTap: () => widget.onItemSelected(4),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// PROFILE IMAGE with height translation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  transform: Matrix4.translationValues(0, isActive ? -8 : 0, 0),
                  child: Container(
                    width: isActive ? 32 : 30,
                    height: isActive ? 32 : 30,
                    padding: isActive ? const EdgeInsets.all(2) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isActive
                          ? Border.all(color: Colors.white, width: 1.5)
                          : Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
                    ),
                    child: ClipOval(
                      child: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: profileImageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => _buildShimmerPlaceholder(),
                              errorWidget: (context, url, error) =>
                                  _buildInitialsPlaceholder(initials, isActive),
                            )
                          : _buildInitialsPlaceholder(initials, isActive),
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                /// WHITE DOT with scale and position animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(0.0, isActive ? -10.0 : -5.0, 0.0)
                    ..multiply(Matrix4.diagonal3Values(
                      isActive ? 1.2 : 1.0,
                      isActive ? 1.2 : 1.0,
                      1.0,
                    )),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isActive ? 1 : 0,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: isActive ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ] : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final cleanName = name.trim().replaceAll(RegExp(r'^@'), '');
    if (cleanName.isEmpty) return 'U';
    return cleanName[0].toUpperCase();
  }

  Widget _buildInitialsPlaceholder(String initials, bool isActive) {
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
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: isActive ? 12 : 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Raleway',
        ),
      ),
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
