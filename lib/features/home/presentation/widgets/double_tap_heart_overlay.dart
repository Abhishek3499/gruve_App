import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_assets.dart';

/// Animated heart overlay shown when a user double-taps on a video.
/// Features elastic bounce scaling, subtle rotation, ambient purple glow, and float-up fade.
/// Positions the heart at the exact double-tap coordinates when [position] is provided.
class DoubleTapHeartOverlay extends StatefulWidget {
  final Offset? position;
  final VoidCallback? onAnimationComplete;

  const DoubleTapHeartOverlay({
    super.key,
    this.position,
    this.onAnimationComplete,
  });

  @override
  State<DoubleTapHeartOverlay> createState() => _DoubleTapHeartOverlayState();
}

class _DoubleTapHeartOverlayState extends State<DoubleTapHeartOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _slideAnimation;

  static const double _heartSize = 110.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 40,
      ),
    ]).animate(_animController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 45),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 35,
      ),
    ]).animate(_animController);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -0.15,
          end: 0.05,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.05,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 65,
      ),
    ]).animate(_animController);

    _slideAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.0), weight: 60),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -35.0,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
    ]).animate(_animController);

    _animController.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildHeartContent() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      // BoxShadow(
                      //   color: Color(0x66990099),
                      //   blurRadius: 28,
                      //   spreadRadius: 6,
                      // ),
                    ],
                  ),
                  child: Image.asset(
                    AppAssets.likeicon,
                    width: _heartSize,
                    height: _heartSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.position != null) {
      return Positioned(
        left: widget.position!.dx - (_heartSize / 2),
        top: widget.position!.dy - (_heartSize / 2),
        width: _heartSize,
        height: _heartSize,
        child: IgnorePointer(child: _buildHeartContent()),
      );
    }

    return Positioned.fill(
      child: IgnorePointer(child: Center(child: _buildHeartContent())),
    );
  }
}
