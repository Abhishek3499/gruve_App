import 'package:flutter/material.dart';
import 'package:gruve_app/features/camera/domain/entities/sticker_data.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

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

  // While a drag/pinch is in progress, the live position/scale/rotation are
  // tracked here and drive `build()` directly via a local setState — this
  // keeps every touch-move frame scoped to just this one sticker's subtree
  // instead of round-tripping through ModeService.notifyListeners(), which
  // triggers a full CameraScreen rebuild (camera preview, toolbar, etc.) on
  // every frame and was the source of the choppy movement/zoom. The
  // committed value is only pushed up to ModeService once, when the
  // gesture ends.
  Offset? _dragPosition;
  double? _dragScale;
  double? _dragRotation;

  TextStyle _getTextStyle(StickerData sticker, double scale) {
    TextStyle style = TextStyle(
      fontSize: 32 * scale,
      fontWeight: FontWeight.bold,
    );

    switch (sticker.fontFamily) {
      case 'Syncopate':
        style = style.copyWith(
          fontFamily: 'Syncopate',
          fontWeight: FontWeight.w700,
        );
        break;
      case 'montserrat':
        style = style.copyWith(
          fontFamily: 'montserrat',
          fontWeight: FontWeight.w600,
        );
        break;
      case 'Courier':
        style = style.copyWith(
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
        );
        break;
      case 'Serif':
        style = style.copyWith(
          fontFamily: 'Serif',
          fontStyle: FontStyle.italic,
        );
        break;
      case 'Raleway':
      default:
        style = style.copyWith(fontFamily: 'Raleway');
        break;
    }

    return style.copyWith(color: sticker.textColor);
  }

  Widget _buildTextContent(StickerData sticker, double scale) {
    final textStyle = _getTextStyle(sticker, scale);

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

    // Default emoji / original fallback — font size scales directly with
    // sticker.scale (rather than a paint-only Transform) so the widget's
    // actual layout size, and therefore its pinch-gesture hit area, grows
    // and shrinks along with what the user visually sees.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Text(
        sticker.text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 32 * scale,
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
          color: AppColors.accentPurple.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.2),
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
                colors: [AppColors.accentPurple, Color(0xFF72008D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.music_note, color: Colors.white, size: 20),
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
                  color: AppColors.accentPurple,
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
    final position = _dragPosition ?? sticker.position;
    final scale = _dragScale ?? sticker.scale;
    final rotation = _dragRotation ?? sticker.rotation;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onScaleStart: (details) {
          _baseScale = sticker.scale;
          _baseRotation = sticker.rotation;
          setState(() {
            _dragPosition = sticker.position;
            _dragScale = sticker.scale;
            _dragRotation = sticker.rotation;
          });
          widget.onTap();
        },
        onScaleUpdate: (details) {
          setState(() {
            _dragPosition =
                (_dragPosition ?? sticker.position) + details.focalPointDelta;
            _dragScale = (_baseScale * details.scale).clamp(0.5, 6.0);
            _dragRotation = _baseRotation + details.rotation;
          });
        },
        onScaleEnd: (details) {
          if (_dragPosition == null) return;
          widget.onUpdate(_dragPosition!, _dragScale!, _dragRotation!);
          setState(() {
            _dragPosition = null;
            _dragScale = null;
            _dragRotation = null;
          });
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
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: Transform(
                alignment: Alignment.center,
                // Text/emoji stickers bake `scale` into their font size
                // above so their real layout size (and hit area) tracks
                // what's on screen; only music stickers (fixed-size badge,
                // no scalable font) still rely on a paint-only Transform
                // scale here.
                transform: sticker.isMusic
                    ? (Matrix4.diagonal3Values(scale, scale, 1.0)
                        ..rotateZ(rotation))
                    : Matrix4.rotationZ(rotation),
                child: Container(
                  // Floors the hit-testable box so a shrunk emoji never
                  // becomes too small to grab — without this, pinching
                  // inward on a small sticker would miss its (now equally
                  // small) gesture region and hit the camera preview
                  // behind it instead, zooming the camera rather than the
                  // sticker. The glyph itself still renders at its true
                  // (possibly smaller) size, top-left within this box.
                  constraints: const BoxConstraints(
                    minWidth: 56,
                    minHeight: 56,
                  ),
                  decoration: BoxDecoration(
                    border: widget.isSelected
                        ? Border.all(color: AppColors.accentPurple, width: 1.5)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: sticker.isMusic
                      ? _buildMusicSticker(sticker)
                      : _buildTextContent(sticker, scale),
                ),
              ),
            ),

            if (widget.isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
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
                        ),
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
