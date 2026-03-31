import 'package:flutter/material.dart';
import 'package:gruve_app/main.dart';

class GetStartedButton extends StatefulWidget {
  final String text;
  final Future<bool> Function() onComplete;
  final bool isLoading;

  const GetStartedButton({
    super.key,
    required this.text,
    required this.onComplete,
    this.isLoading = false,
  });

  @override
  State<GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<GetStartedButton>
    with RouteAware, SingleTickerProviderStateMixin {
  double _dragX = 0;
  bool _internalLoading = false;

  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;

  static const double _buttonWidth = 200;
  static const double _buttonHeight = 50;
  static const double _circleSize = 45;

  double get _maxDrag => _buttonWidth - _circleSize - 5;
  double get _center => _maxDrag / 2; // ← center point

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    _snapController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _snapTo(0);
  }

  void _snapTo(double target) {
    _snapController.stop();
    final start = _dragX;

    _snapAnimation =
        Tween<double>(begin: start, end: target).animate(
          CurvedAnimation(
            parent: _snapController,
            curve: target >= _maxDrag
                ? Curves
                      .easeOutBack // forward → slight bounce
                : Curves.easeOutCubic, // back → smooth
          ),
        )..addListener(() {
          if (mounted) setState(() => _dragX = _snapAnimation!.value);
        });

    _snapController.forward(from: 0);
  }

  Future<void> _handleRelease() async {
    if (_internalLoading || widget.isLoading) return;

    if (_dragX >= _center) {
      // ✅ Past center → try to complete
      bool success = false;
      try {
        if (!mounted) return;
        success = await widget.onComplete();
      } catch (_) {
        success = false;
      }

      if (!mounted) return;

      if (success) {
        _snapTo(_maxDrag);
        _snapController.addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _internalLoading = true);
          }
        });
      } else {
        _snapTo(0); // validation fail → reset
      }
    } else {
      // ❌ Before center → snap back left
      _snapTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = widget.isLoading || _internalLoading;

    return SizedBox(
      width: _buttonWidth,
      height: _buttonHeight,
      child: Stack(
        children: [
          // Shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(64),
                  offset: const Offset(0, 4),
                  blurRadius: 20,
                ),
              ],
            ),
          ),

          // Background
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF9544A7),
              borderRadius: BorderRadius.circular(100),
            ),
          ),

          // Inset gradient
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

          // Text fades out as circle moves right
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(left: _circleSize + 14, right: 16),
                child: Opacity(
                  opacity: (1 - (_dragX / _center)).clamp(0.0, 1.0),
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
          ),

          // Circle
          Positioned(
            left: _dragX,
            top: (_buttonHeight - _circleSize) / 2,
            child: GestureDetector(
              onPanStart: isBusy
                  ? null
                  : (_) {
                      _snapController.stop();
                      // sync position to wherever snap stopped
                      if (_snapAnimation != null) {
                        _dragX = _snapAnimation!.value;
                      }
                      setState(() {});
                    },
              onPanUpdate: isBusy
                  ? null
                  : (d) {
                      setState(() {
                        _dragX = (_dragX + d.delta.dx).clamp(0, _maxDrag);
                      });
                    },
              onPanEnd: isBusy ? null : (_) => _handleRelease(),
              child: Container(
                width: _circleSize,
                height: _circleSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: isBusy
                    ? const Center(
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF9544A7),
                          ),
                        ),
                      )
                    : const Icon(
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
