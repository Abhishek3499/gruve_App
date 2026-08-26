import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gruve_app/features/camera/domain/entities/sticker_data.dart';

class StoryTextEditor extends StatefulWidget {
  final StickerData? initialSticker;

  const StoryTextEditor({
    super.key,
    this.initialSticker,
  });

  static Future<StickerData?> open(BuildContext context, {StickerData? initialSticker}) {
    return showGeneralDialog<StickerData>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'TextEditor',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StoryTextEditor(initialSticker: initialSticker);
      },
    );
  }

  @override
  State<StoryTextEditor> createState() => _StoryTextEditorState();
}

class _StoryTextEditorState extends State<StoryTextEditor> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Formatting state
  late Color _textColor;
  late Color _backgroundColor;
  late String _fontFamily;
  late bool _hasBackground;
  late TextAlign _textAlign;

  final List<Color> _colors = const [
    Colors.white,
    Colors.black,
    Color(0xFFFF2D55), // Red
    Color(0xFFFFCC00), // Yellow
    Color(0xFFC358D7), // Purple
    Color(0xFFFF9500), // Orange
    Color(0xFF4CD964), // Green
    Color(0xFF5AC8FA), // Blue
    Color(0xFFFF2D85), // Pink
  ];

  final List<Map<String, String>> _fonts = const [
    {'name': 'Modern', 'family': 'Raleway'},
    {'name': 'Futuristic', 'family': 'Syncopate'},
    {'name': 'Stylized', 'family': 'montserrat'},
    {'name': 'Typewriter', 'family': 'Courier'},
    {'name': 'Serif', 'family': 'Serif'},
  ];

  @override
  void initState() {
    super.initState();

    final s = widget.initialSticker;
    _controller.text = s?.text ?? '';
    _textColor = s?.textColor ?? Colors.white;
    _backgroundColor = s?.backgroundColor ?? Colors.black;
    _fontFamily = s?.fontFamily ?? 'Raleway';
    _hasBackground = s?.hasBackground ?? false;
    _textAlign = s?.textAlign ?? TextAlign.center;

    // Focus and open keyboard automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleBackground() {
    setState(() {
      _hasBackground = !_hasBackground;
      // If turning background on and text is black, make bg white. If text is white, make bg black.
      if (_hasBackground) {
        if (_textColor == Colors.black) {
          _backgroundColor = Colors.white;
        } else if (_textColor == Colors.white) {
          _backgroundColor = Colors.black;
        } else {
          _backgroundColor = Colors.black.withValues(alpha: 0.6);
        }
      }
    });
  }

  void _toggleAlignment() {
    setState(() {
      switch (_textAlign) {
        case TextAlign.center:
          _textAlign = TextAlign.left;
          break;
        case TextAlign.left:
          _textAlign = TextAlign.right;
          break;
        case TextAlign.right:
        default:
          _textAlign = TextAlign.center;
          break;
      }
    });
  }

  TextStyle _getTextStyle() {
    TextStyle style = const TextStyle(fontSize: 36, fontWeight: FontWeight.bold);

    switch (_fontFamily) {
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

    return style.copyWith(color: _textColor);
  }

  void _onDone() {
    if (_controller.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }

    final result = (widget.initialSticker ?? StickerData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '',
      position: const Offset(100, 200),
    )).copyWith(
      text: _controller.text,
      isText: true,
      textColor: _textColor,
      backgroundColor: _backgroundColor,
      fontFamily: _fontFamily,
      hasBackground: _hasBackground,
      textAlign: _textAlign,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = _getTextStyle();
    final alignmentIcon = _textAlign == TextAlign.center
        ? Icons.format_align_center
        : _textAlign == TextAlign.left
            ? Icons.format_align_left
            : Icons.format_align_right;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background
          Positioned.fill(
            child: GestureDetector(
              onTap: _onDone,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.black54),
              ),
            ),
          ),

          // Main Editor Layout
          SafeArea(
            child: Column(
              children: [
                // Top controls toolbar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Alignment Toggle
                      IconButton(
                        icon: Icon(alignmentIcon, color: Colors.white, size: 28),
                        onPressed: _toggleAlignment,
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Background highlight toggle
                          IconButton(
                            icon: Icon(
                              _hasBackground ? Icons.font_download : Icons.font_download_outlined,
                              color: _hasBackground ? const Color(0xFFC358D7) : Colors.white,
                              size: 28,
                            ),
                            onPressed: _toggleBackground,
                          ),
                          const SizedBox(width: 8),
                          // Done Button
                          GestureDetector(
                            onTap: _onDone,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC358D7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Done',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Center Input Text Area
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: IntrinsicWidth(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: _hasBackground
                              ? BoxDecoration(
                                  color: _backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textAlign: _textAlign,
                            style: textStyle,
                            cursorColor: const Color(0xFFC358D7),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'Type something...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 32),
                            ),
                            onSubmitted: (_) => _onDone(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Styling Controls
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Color Selection Row
                      SizedBox(
                        height: 36,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _colors.length,
                          itemBuilder: (context, index) {
                            final color = _colors[index];
                            final isSelected = _textColor == color;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _textColor = color;
                                  if (_hasBackground) {
                                    // Make sure background has high contrast
                                    if (color == Colors.white) {
                                      _backgroundColor = Colors.black;
                                    } else if (color == Colors.black) {
                                      _backgroundColor = Colors.white;
                                    }
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                  border: isSelected
                                      ? Border.all(color: Colors.white, width: 3)
                                      : Border.all(color: Colors.white24, width: 1.5),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Font Style Slider Row
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _fonts.length,
                          itemBuilder: (context, index) {
                            final font = _fonts[index];
                            final isSelected = _fontFamily == font['family'];

                            // Get simple font styles for the preview buttons
                            TextStyle itemStyle = TextStyle(
                              color: isSelected ? const Color(0xFFC358D7) : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            );
                            if (font['family'] == 'Syncopate') {
                              itemStyle = itemStyle.copyWith(fontFamily: 'Syncopate');
                            } else if (font['family'] == 'montserrat') {
                              itemStyle = itemStyle.copyWith(fontFamily: 'montserrat');
                            } else if (font['family'] == 'Courier') {
                              itemStyle = itemStyle.copyWith(fontFamily: 'Courier');
                            } else if (font['family'] == 'Serif') {
                              itemStyle = itemStyle.copyWith(fontFamily: 'Serif', fontStyle: FontStyle.italic);
                            }

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _fontFamily = font['family']!;
                                });
                              },
                              child: Container(
                                alignment: Alignment.center,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white10,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFC358D7) : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  font['name']!,
                                  style: itemStyle,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
