import 'package:flutter/material.dart';
import 'package:gruve_app/main.dart';

class GetStartedButtonController {
  _GetStartedButtonState? _state;

  bool get isBusy => _state?._isBusy ?? false;

  Future<bool> submit() async {
    final state = _state;
    if (state == null) return false;
    return state._submitFromKeyboard();
  }

  void reset() {
    _state?._resetButton();
  }

  void _attach(_GetStartedButtonState state) {
    _state = state;
  }

  void _detach(_GetStartedButtonState state) {
    if (_state == state) {
      _state = null;
    }
  }
}

class GetStartedButton extends StatefulWidget {
  final String text;
  final Future<bool> Function() onComplete;
  final bool isLoading;
  final GetStartedButtonController? controller;

  const GetStartedButton({
    super.key,
    required this.text,
    required this.onComplete,
    this.isLoading = false,
    this.controller,
  });

  @override
  State<GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<GetStartedButton>
    with RouteAware, SingleTickerProviderStateMixin {
  static const double _buttonWidth = 200;
  static const double _buttonHeight = 50;
  static const double _circleSize = 45;

  double _dragX = 0;
  bool _internalLoading = false;
  bool _isSubmitting = false;
  bool _lockAfterSnap = false;

  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;
  VoidCallback? _snapAnimationListener;

  double get _maxDrag => _buttonWidth - _circleSize - 5;
  double get _center => _maxDrag / 2;
  bool get _isBusy => widget.isLoading || _internalLoading || _isSubmitting;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _snapController.addStatusListener(_handleSnapStatus);
  }

  @override
  void didUpdateWidget(covariant GetStartedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    final listener = _snapAnimationListener;
    if (listener != null) {
      _snapAnimation?.removeListener(listener);
    }
    _snapController.removeStatusListener(_handleSnapStatus);
    _snapController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _resetButton();
  }

  void _resetButton() {
    _lockAfterSnap = false;
    if (mounted) {
      setState(() {
        _internalLoading = false;
        _isSubmitting = false;
      });
    }
    _snapTo(0);
  }

  void _handleSnapStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_lockAfterSnap || !mounted) {
      return;
    }

    _lockAfterSnap = false;
    if (_dragX >= _maxDrag - 0.5) {
      setState(() => _internalLoading = true);
    }
  }

  void _snapTo(double target) {
    _snapController.stop();
    final start = _dragX;
    final previousListener = _snapAnimationListener;
    if (previousListener != null) {
      _snapAnimation?.removeListener(previousListener);
    }

    final animation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(
        parent: _snapController,
        curve: target >= _maxDrag ? Curves.easeOutBack : Curves.easeOutCubic,
      ),
    );
    _snapAnimation = animation;
    _snapAnimationListener = () {
      if (mounted) setState(() => _dragX = animation.value);
    };
    animation.addListener(_snapAnimationListener!);

    _snapController.forward(from: 0);
  }

  Future<bool> _submitFromKeyboard() {
    return _runCompletion(animateForwardFirst: true);
  }

  Future<bool> _runCompletion({required bool animateForwardFirst}) async {
    if (_isBusy) return false;

    if (animateForwardFirst) {
      _snapTo(_maxDrag);
    }

    setState(() => _isSubmitting = true);

    bool success = false;
    try {
      if (!mounted) return false;
      success = await widget.onComplete();
    } catch (_) {
      success = false;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (!mounted) return success;

    if (success) {
      if (_dragX >= _maxDrag - 0.5 && !_snapController.isAnimating) {
        setState(() => _internalLoading = true);
      } else {
        _lockAfterSnap = true;
        _snapTo(_maxDrag);
      }
    } else {
      _lockAfterSnap = false;
      _snapTo(0);
    }

    return success;
  }

  Future<void> _handleRelease() async {
    if (_isBusy) return;

    if (_dragX >= _center) {
      await _runCompletion(animateForwardFirst: true);
    } else {
      _snapTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isBusy;

    return Semantics(
      button: true,
      enabled: !isBusy,
      label: widget.text,
      child: SizedBox(
        width: _buttonWidth,
        height: _buttonHeight,
        child: Stack(
          children: [
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
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF9544A7),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
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
            Positioned(
              left: _dragX,
              top: (_buttonHeight - _circleSize) / 2,
              child: GestureDetector(
                onPanStart: isBusy
                    ? null
                    : (_) {
                        _snapController.stop();
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
      ),
    );
  }
}
