import 'package:flutter/material.dart';
import 'package:gruve_app/features/home/controllers/subscribe_controller.dart';
import 'package:gruve_app/features/home/models/subscribe_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class SubscribeButton extends StatefulWidget {
  final String userId;
  final String username;
  final SubscribeController subscribeController;
  final bool initialIsSubscribed;

  const SubscribeButton({
    super.key,
    required this.userId,
    required this.username,
    required this.subscribeController,
    this.initialIsSubscribed = false,
  });

  @override
  State<SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<SubscribeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  double _dragPosition = 0.0;
  bool _isDragging = false;

  void _log(String message) {
    AppLogger.d('🪪 [ProfileSubscribeButton] $message');
  }

  @override
  void initState() {
    super.initState();
    _log(
      '🛠️ initState userId=${widget.userId} username=${widget.username} initial=${widget.initialIsSubscribed}',
    );
    _ensureUserRegistered(widget.initialIsSubscribed);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SubscribeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _log(
        '🔁 didUpdateWidget userId changed ${oldWidget.userId} -> ${widget.userId}',
      );
      _ensureUserRegistered(widget.initialIsSubscribed, force: true);
    }
  }

  void _ensureUserRegistered(bool isSubscribed, {bool force = false}) {
    _log(
      '🧱 ensureUserRegistered userId=${widget.userId} incoming=$isSubscribed force=$force',
    );
    final existing = widget.subscribeController.getUserSubscribeModel(
      widget.userId,
    );
    if (existing != null && !force) {
      _log('📦 existing model found, skipping reseed userId=${widget.userId}');
      return;
    }

    final resolvedState = existing?.isSubscribed ?? isSubscribed;
    _log(
      '🧠 resolved seed state userId=${widget.userId} resolved=$resolvedState',
    );
    widget.subscribeController.addOrUpdateUser(
      SubscribeModel(
        userId: widget.userId,
        username: widget.username,
        isSubscribed: resolvedState,
        subscribedAt: resolvedState ? DateTime.now() : null,
      ),
    );
  }

  void _showSubscriptionSnackBar(bool isSubscribed) {
    _log('🍞 show snackbar state=$isSubscribed userId=${widget.userId}');
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isSubscribed
              ? 'Subscribed to ${widget.username}'
              : 'Unsubscribed from ${widget.username}',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _performToggle(BuildContext context, bool currentStatus) async {
    final optimisticStatus = !currentStatus;
    _log(
      '🔄 toggle userId=${widget.userId} current=$currentStatus optimistic=$optimisticStatus',
    );
    _showSubscriptionSnackBar(optimisticStatus);

    try {
      final result = await widget.subscribeController.toggleSubscription(
        widget.userId,
      );
      _log(
        '✅ toggleSubscription future resolved userId=${widget.userId} result=$result',
      );
    } catch (e) {
      _log('❌ button error userId=${widget.userId} error=$e');
      if (!context.mounted) {
        return;
      }

      String errorMessage =
          'Failed to ${currentStatus ? 'unsubscribe from' : 'subscribe to'} ${widget.username}';

      if (e.toString().contains('subscribe to yourself')) {
        errorMessage = 'You cannot subscribe to yourself';
      } else if (e.toString().contains('405') ||
          e.toString().contains('Method Not Allowed')) {
        errorMessage =
            'Subscription service unavailable. Please try again later.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _log('🚨 error snackbar shown userId=${widget.userId}');

      // Reset drag position if subscription failed
      if (!currentStatus) {
        setState(() {
          _dragPosition = 0.0;
        });
      }
    }
  }

  Widget _buildSliderWidget(BuildContext context) {
    const double totalWidth = 130.0;
    const double thumbSize = 30.0;
    const double padding = 4.0;
    const double maxDragDistance = totalWidth - thumbSize - (padding * 2);

    return Container(
      width: totalWidth,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFE24E0), Color(0xFF72008D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFE24E0).withValues(alpha: 0.4),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 01),
              child: Opacity(
                opacity: (1.0 - (_dragPosition / (maxDragDistance * 0.75)))
                    .clamp(0.0, 1.0),
                child: const Text(
                  'Slide to Subscribe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: padding + _dragPosition,
            top: padding,
            bottom: padding,
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                _animationController.stop();
                setState(() {
                  _isDragging = true;
                });
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragPosition = (_dragPosition + details.primaryDelta!).clamp(
                    0.0,
                    maxDragDistance,
                  );
                });
              },
              onHorizontalDragEnd: (details) {
                setState(() {
                  _isDragging = false;
                });

                _animationController.stop();

                if (_dragPosition >= maxDragDistance * 0.8) {
                  _slideAnimation =
                      Tween<double>(
                          begin: _dragPosition,
                          end: maxDragDistance,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.easeOut,
                          ),
                        )
                        ..addListener(() {
                          setState(() {
                            _dragPosition = _slideAnimation.value;
                          });
                        });

                  _animationController.forward(from: 0.0).then((_) {
                    _performToggle(context, false);
                  });
                } else {
                  _slideAnimation =
                      Tween<double>(begin: _dragPosition, end: 0.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOut,
                        ),
                      )..addListener(() {
                        setState(() {
                          _dragPosition = _slideAnimation.value;
                        });
                      });

                  _animationController.forward(from: 0.0);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: thumbSize,
                height: thumbSize,
                transform: Matrix4.identity()
                  ..scaleByDouble(
                    _isDragging ? 1.08 : 1.0,
                    _isDragging ? 1.08 : 1.0,
                    1.0,
                    1.0,
                  ),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isDragging ? 0.25 : 0.15,
                      ),
                      blurRadius: _isDragging ? 6 : 4,
                      offset: Offset(0, _isDragging ? 3 : 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFFFE24E0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribedWidget(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _performToggle(context, true),
        child: Container(
          width: 130,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF33123B).withValues(alpha: 0.6),
            border: Border.all(color: const Color(0xFFFE24E0), width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12, right: 38),
                child: Center(
                  child: Text(
                    'Subscribed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                bottom: 4,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Color(0xFFFE24E0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.subscribeController,
      builder: (context, child) {
        final isSubscribed = widget.subscribeController.isUserSubscribed(
          widget.userId,
        );
        _log(
          '🎨 rebuild userId=${widget.userId} username=${widget.username} isSubscribed=$isSubscribed',
        );

        if (isSubscribed) {
          _dragPosition = 0.0;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: isSubscribed
              ? _buildSubscribedWidget(context)
              : _buildSliderWidget(context),
        );
      },
    );
  }
}
