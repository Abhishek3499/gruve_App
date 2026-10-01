import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gruve_app/features/home/presentation/controllers/post_share_flow_bridge.dart';
import 'package:gruve_app/features/home/presentation/controllers/post_upload_progress_state.dart';
import 'package:gruve_app/features/home/presentation/widgets/gradient_circular_progress_painter.dart';

/// A small floating upload progress bubble on the right side of the Reel/Home feed.
/// Shows animated circular progress (e.g. 62%) with Gruve purple/pink gradient.
/// Wrapped in [IgnorePointer] to ensure non-blocking gesture pass-through for reels.
class FloatingUploadProgressBubble extends StatefulWidget {
  const FloatingUploadProgressBubble({super.key});

  @override
  State<FloatingUploadProgressBubble> createState() =>
      _FloatingUploadProgressBubbleState();
}

class _FloatingUploadProgressBubbleState
    extends State<FloatingUploadProgressBubble>
    with TickerProviderStateMixin {
  late AnimationController _visibilityController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 320),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.8, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _visibilityController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial check
    if (PostShareFlowBridge.uploadProgress.value.isVisible) {
      _visibilityController.forward();
    }
  }

  @override
  void dispose() {
    _visibilityController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return ValueListenableBuilder<PostUploadProgressState>(
      valueListenable: PostShareFlowBridge.uploadProgress,
      builder: (context, state, _) {
        if (state.isVisible) {
          if (!_visibilityController.isAnimating &&
              _visibilityController.value < 1.0) {
            _visibilityController.forward();
          }
        } else {
          if (!_visibilityController.isAnimating &&
              _visibilityController.value > 0.0) {
            _visibilityController.reverse();
          }
        }

        return Positioned(
          top: topInset + 76,
          left: 14,
          child: IgnorePointer(
            ignoring: true, // Non-blocking: 100% gesture pass-through to feed
            child: AnimatedBuilder(
              animation: _visibilityController,
              builder: (context, child) {
                if (_visibilityController.value == 0.0) {
                  return const SizedBox.shrink();
                }

                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  ),
                );
              },
              child: _buildBubbleContent(state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBubbleContent(PostUploadProgressState state) {
    const double bubbleSize = 56.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: bubbleSize,
          height: bubbleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Vibrant Gruve purple/pink ambient glow
              BoxShadow(
                color: const Color(0xFFD42BC2).withValues(
                  alpha: state.isCompleted
                      ? 0.75
                      : (0.45 * _pulseAnimation.value),
                ),
                blurRadius: state.isCompleted ? 20 : 14,
                spreadRadius: state.isCompleted ? 2 : 1,
              ),
              BoxShadow(
                color: const Color(0xFF9544A7).withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 0,
              ),
              // Dark grounding shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background disc
          Container(
            width: bubbleSize,
            height: bubbleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(0.0, -0.3),
                radius: 0.9,
                colors: [
                  Color(0xFF381245), // Deep plum
                  Color(0xFF1E092D), // Dark purple/black
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1.2,
              ),
            ),
          ),

          // Optional media preview thumbnail (darkened for high text legibility)
          if (state.mediaPath != null &&
              state.mediaPath!.isNotEmpty &&
              !state.isVideo &&
              File(state.mediaPath!).existsSync())
            ClipOval(
              child: SizedBox(
                width: bubbleSize - 8,
                height: bubbleSize - 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(state.mediaPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                    Container(
                      color: const Color(0xFF220A2E).withValues(alpha: 0.65),
                    ),
                  ],
                ),
              ),
            ),

          // Animated Circular Progress Ring with Gruve purple/pink gradient
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: state.progress.clamp(0.0, 100.0),
            ),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, _) {
              return CustomPaint(
                size: const Size(bubbleSize, bubbleSize),
                painter: GradientCircularProgressPainter(
                  progress: animatedProgress / 100.0,
                  isCompleted: state.isCompleted,
                  isFailed: state.isFailed,
                ),
              );
            },
          ),

          // Center Status indicator (Percentage / Checkmark / Error)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: state.progress.clamp(0.0, 100.0),
            ),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, _) {
              if (state.isCompleted) {
                return _buildSuccessCheckmark();
              }

              if (state.isFailed) {
                return _buildErrorIndicator();
              }

              return _buildProgressPercentage(animatedProgress);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPercentage(double progress) {
    final int percentValue = progress.toInt().clamp(0, 100);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "$percentValue%",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.0,
            fontWeight: FontWeight.w900,
            fontFamily: 'Outfit',
            letterSpacing: -0.3,
            shadows: [
              Shadow(
                color: Colors.black87,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCheckmark() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF3AFF), // Neon pink
                  Color(0xFFC358D7), // Accent purple
                  Color(0xFF9544A7), // Gruve purple
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF3AFF),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorIndicator() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE53935).withValues(alpha: 0.9),
      ),
      child: const Center(
        child: Icon(
          Icons.priority_high_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
