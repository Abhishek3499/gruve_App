import 'package:flutter/material.dart';
import 'package:gruve_app/shared/widgets/optimized/optimized_image.dart';

/// Three-dot animated typing bubble shown in the message list.
class TypingBubble extends StatefulWidget {
  final String? avatarUrl;
  final String name;

  const TypingBubble({super.key, required this.avatarUrl, required this.name});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        OptimizedAvatar(
          imageUrl: widget.avatarUrl,
          name: widget.name,
          radius: 14,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${widget.name} is typing',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 6),
              ...List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    final offset = ((_controller.value * 3) - i) % 3.0;
                    final scale = offset < 1.0
                        ? 0.6 + 0.4 * offset
                        : offset < 2.0
                        ? 1.0 - 0.4 * (offset - 1.0)
                        : 0.6;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 5 * scale,
                      height: 5 * scale,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
