import 'package:flutter/material.dart';
import 'package:gruve_app/screens/auth/api/controllers/logout_controller.dart';
import 'package:gruve_app/screens/auth/screens/sign_in_screen.dart';

class LogoutWidget extends StatelessWidget {
  final LogoutController _logoutController = LogoutController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          /// MAIN CARD
          Container(
            margin: const EdgeInsets.only(top: 30),
            child: ClipPath(
              clipper: TopCurveClipper(),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 55, 24, 28),
                color: const Color(0xFF5A1E67),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 55),

                    const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "Are you sure you want to logout from your account?",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),

                    const SizedBox(height: 27),

                    /// LOGOUT BUTTON
                    GestureDetector(
                      onTap: () async {
                        print("🔥 YES CLICKED");
                        final navigator = Navigator.of(context);
                        navigator.pop();

                        await _logoutController.logout();

                        print("🔥 LOGOUT DONE");

                        // ❌ don't use old context
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                          (route) => false,
                        );
                      },

                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8E2DE2), Color(0xFF72008D)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withValues(alpha: 0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "Yes",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// FLOATING CLOSE BUTTON
          Positioned(
            top: 53,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF72008D)],
                  ),
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double radius = 30.0;
    const double bumpHeight = 35.0; // card ka top offset
    const double bumpWidth = 51.0; // curve width - chota
    const double bumpUp = 22.0; // kitna upar jayega - subtle

    double center = size.width / 2;

    final Path path = Path();

    path.moveTo(radius, bumpHeight);
    path.lineTo(center - bumpWidth, bumpHeight);

    // Subtle bump UP
    path.cubicTo(
      center - bumpWidth + 10,
      bumpHeight,
      center - 18,
      bumpHeight - bumpUp,
      center,
      bumpHeight - bumpUp,
    );
    path.cubicTo(
      center + 18,
      bumpHeight - bumpUp,
      center + bumpWidth - 10,
      bumpHeight,
      center + bumpWidth,
      bumpHeight,
    );

    // Top-right corner
    path.lineTo(size.width - radius, bumpHeight);
    path.quadraticBezierTo(
      size.width,
      bumpHeight,
      size.width,
      bumpHeight + radius,
    );

    // Right side
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );

    // Bottom
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    // Left side
    path.lineTo(0, bumpHeight + radius);
    path.quadraticBezierTo(0, bumpHeight, radius, bumpHeight);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
