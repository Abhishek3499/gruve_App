import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/screens/auth/screens/sign_in_screen.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'package:gruve_app/widgets/video_background.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VideoBackground(
        videoPath: AppAssets.splashVideo,
        overlayOpacity: 0.85,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(),
                  Image.asset(AppAssets.logoMain, width: 90),
                  const SizedBox(height: 24),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Lights. ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppAssets.syncopateFont,
                            height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'Camera.\n',
                          style: TextStyle(
                            color: Color(0xFF9B4DFF),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppAssets.syncopateFont,
                            height: 1.2,
                          ),
                        ),
                         WidgetSpan(child: SizedBox(height: 12)),
                        TextSpan(
                          text: 'Fame Begins.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppAssets.syncopateFont,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GetStartedButton(
                    text: 'To Get Started',
                    onComplete: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// class _SlidingButton extends StatefulWidget {
//   final String text;
//   final VoidCallback onComplete;

//   const _SlidingButton({
//     super.key,
//     required this.text,
//     required this.onComplete,
//   });

//   @override
//   State<_SlidingButton> createState() => _SlidingButtonState();
// }

// class _SlidingButtonState extends State<_SlidingButton> {
//   double _dragPosition = 0.0;
//   bool _isAnimating = false;

//   double get _maxDragDistance {
//     return 280.0;
//   }

//   double get _threshold => _maxDragDistance / 2;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: _maxDragDistance + 60,
//       height: 55,
//       decoration: BoxDecoration(
//         color: Colors.white.withAlpha(26),
//         borderRadius: BorderRadius.circular(30),
//         border: Border.all(color: Colors.white.withAlpha(8), width: 1),
//       ),
//       child: Stack(
//         children: [
//           Center(
//             child: Text(
//               widget.text,
//               style: TextStyle(
//                 color: Colors.white.withAlpha(178),
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           AnimatedPositioned(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//             left: _dragPosition,
//             top: 0,
//             bottom: 0,
//             child: GestureDetector(
//               onPanUpdate: (details) {
//                 if (_isAnimating) return;

//                 setState(() {
//                   _dragPosition += details.delta.dx;
//                   _dragPosition = _dragPosition.clamp(0.0, _maxDragDistance);
//                 });
//               },
//               onPanEnd: (details) {
//                 if (_isAnimating) return;

//                 setState(() {
//                   _isAnimating = true;

//                   if (_dragPosition >= _threshold) {
//                     _dragPosition = _maxDragDistance;

//                     Future.delayed(const Duration(milliseconds: 300), () {
//                       if (!mounted) return;
//                       widget.onComplete();
//                     });
//                   } else {
//                     _dragPosition = 0.0;

//                     Future.delayed(const Duration(milliseconds: 300), () {
//                       if (!mounted) return;
//                       setState(() {
//                         _isAnimating = false;
//                       });
//                     });
//                   }
//                 });
//               },
//               child: Container(
//                 width: 53,
//                 height: 50,
//                 margin: const EdgeInsets.all(2.5),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Center(
//                   child: Icon(
//                     Icons.keyboard_double_arrow_right,
//                     size: 22,
//                     color: Color(0xFF9B4DFF),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
