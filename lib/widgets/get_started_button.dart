import 'package:flutter/material.dart';
import 'package:gruve_app/main.dart';

class GetStartedButton extends StatefulWidget {
  final String text;
  final VoidCallback onComplete;

  const GetStartedButton({
    super.key,
    required this.text,
    required this.onComplete,
  });

  @override
  State<GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<GetStartedButton> with RouteAware {
  double _dragX = 0;
  bool _animating = false;

  static const double _buttonWidth = 200;
  static const double _buttonHeight = 50;
  static const double _circleSize = 45;

  double get _maxDrag => _buttonWidth - _circleSize - 5;
  double get _threshold => _maxDrag * 0.6;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// 🔥 THIS IS THE KEY
  @override
  void didPopNext() {
    setState(() {
      _dragX = 0; // ⬅️ reset when coming back
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _buttonWidth,
      height: _buttonHeight,
      child: Stack(
        children: [
          // Outer shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 20,
                ),
              ],
            ),
          ),

          // Button background
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF9544A7),
              borderRadius: BorderRadius.circular(100),
            ),
          ),

          // Inset shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xCC5C1B6D), Colors.transparent],
              ),
            ),
          ),

          // Text
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(left: _circleSize + 14, right: 16),
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'syncopate',
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),

          // Sliding circle
          Positioned(
            left: _dragX,
            top: (_buttonHeight - _circleSize) / 2,
            child: GestureDetector(
              onPanUpdate: (d) {
                if (_animating) return;
                setState(() {
                  _dragX = (_dragX + d.delta.dx).clamp(0, _maxDrag);
                });
              },
              onPanEnd: (_) async {
                if (_animating) return;
                _animating = true;

                if (_dragX >= _threshold) {
                  setState(() => _dragX = _maxDrag);
                  await Future.delayed(const Duration(milliseconds: 220));
                  widget.onComplete();
                } else {
                  setState(() => _dragX = 0);
                }

                await Future.delayed(const Duration(milliseconds: 180));
                _animating = false;
              },
              child: Container(
                width: _circleSize,
                height: _circleSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_double_arrow_right,
                  size: 20,
                  color: Color(0xFF9544A7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
