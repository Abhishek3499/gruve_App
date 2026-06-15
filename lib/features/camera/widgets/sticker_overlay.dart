import 'package:flutter/material.dart';
import '../models/sticker_data.dart';

class StickerOverlay extends StatefulWidget {
  final StickerData sticker;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(Offset position, double scale, double rotation) onUpdate;

  const StickerOverlay({
    super.key,
    required this.sticker,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<StickerOverlay> createState() => _StickerOverlayState();
}

class _StickerOverlayState extends State<StickerOverlay> {
  late double _baseScale;
  late double _baseRotation;

  @override
  Widget build(BuildContext context) {
    final sticker = widget.sticker;

    return Positioned(
      left: sticker.position.dx,
      top: sticker.position.dy,
      child: GestureDetector(
        onScaleStart: (details) {
          _baseScale = sticker.scale;
          _baseRotation = sticker.rotation;
          widget.onTap();
        },
        onScaleUpdate: (details) {
          // Since focalPointDelta is provided frame-by-frame, we can accumulate it:
          final updatedPos = sticker.position + details.focalPointDelta;
          
          // Calculate new scale and rotation
          final updatedScale = (_baseScale * details.scale).clamp(0.5, 6.0);
          final updatedRotation = _baseRotation + details.rotation;

          widget.onUpdate(updatedPos, updatedScale, updatedRotation);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Inner content with scale and rotation
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(sticker.scale, sticker.scale, 1.0)
                ..rotateZ(sticker.rotation),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: widget.isSelected
                      ? Border.all(color: const Color(0xFFC358D7), width: 1.5)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sticker.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Delete button on top-right (only when selected)
            if (widget.isSelected)
              Positioned(
                top: -12,
                right: -12,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
