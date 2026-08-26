import 'package:flutter/material.dart';
import 'package:gruve_app/features/camera/domain/entities/sticker_data.dart';

class StickerOverlay extends StatefulWidget {
  final StickerData sticker;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final Function(Offset position, double scale, double rotation) onUpdate;

  const StickerOverlay({
    super.key,
    required this.sticker,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onUpdate,
    this.onEdit,
  });

  @override
  State<StickerOverlay> createState() => _StickerOverlayState();
}

class _StickerOverlayState extends State<StickerOverlay> {
  late double _baseScale;
  late double _baseRotation;

  TextStyle _getTextStyle(StickerData sticker) {
    TextStyle style = const TextStyle(fontSize: 32, fontWeight: FontWeight.bold);

    switch (sticker.fontFamily) {
      case 'Syncopate':
        style = style.copyWith(fontFamily: 'Syncopate', fontWeight: FontWeight.w700);
        break;
      case 'montserrat':
        style = style.copyWith(fontFamily: 'montserrat', fontWeight: FontWeight.w600);
        break;
      case 'Courier':
        style = style.copyWith(fontFamily: 'Courier', fontWeight: FontWeight.bold);
        break;
      case 'Serif':
        style = style.copyWith(fontFamily: 'Serif', fontStyle: FontStyle.italic);
        break;
      case 'Raleway':
      default:
        style = style.copyWith(fontFamily: 'Raleway');
        break;
    }

    return style.copyWith(color: sticker.textColor);
  }

  Widget _buildTextContent(StickerData sticker) {
    final textStyle = _getTextStyle(sticker);

    if (sticker.isText) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: sticker.hasBackground
            ? BoxDecoration(
                color: sticker.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Text(
          sticker.text,
          style: textStyle,
          textAlign: sticker.textAlign,
        ),
      );
    }

    // Default emoji / original fallback
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Text(
        sticker.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMusicSticker(StickerData sticker) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC358D7).withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC358D7).withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFC358D7), Color(0xFF72008D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.music_note,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sticker.musicTitle ?? 'Unknown Track',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Raleway',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sticker.musicArtist ?? 'Unknown Artist',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontFamily: 'Raleway',
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (index) {
              return Container(
                width: 3,
                height: [14.0, 20.0, 10.0, 16.0][index],
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFC358D7),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

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
          final updatedPos = sticker.position + details.focalPointDelta;
          final updatedScale = (_baseScale * details.scale).clamp(0.5, 6.0);
          final updatedRotation = _baseRotation + details.rotation;

          widget.onUpdate(updatedPos, updatedScale, updatedRotation);
        },
        onTap: () {
          if (widget.isSelected) {
            widget.onEdit?.call();
          } else {
            widget.onTap();
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(sticker.scale, sticker.scale, 1.0)
                ..rotateZ(sticker.rotation),
              child: Container(
                decoration: BoxDecoration(
                  border: widget.isSelected
                      ? Border.all(color: const Color(0xFFC358D7), width: 1.5)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: sticker.isMusic
                    ? _buildMusicSticker(sticker)
                    : _buildTextContent(sticker),
              ),
            ),

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
