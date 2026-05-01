import 'package:flutter/material.dart';
import 'package:gruve_app/features/home/controllers/subscribe_controller.dart';
import 'package:gruve_app/features/home/models/subscribe_model.dart';

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

class _SubscribeButtonState extends State<SubscribeButton> {
  void _log(String message) {
    debugPrint('🪪 [ProfileSubscribeButton] $message');
  }

  @override
  void initState() {
    super.initState();
    _log(
      '🛠️ initState userId=${widget.userId} username=${widget.username} initial=${widget.initialIsSubscribed}',
    );
    _ensureUserRegistered(widget.initialIsSubscribed);
  }

  @override
  void didUpdateWidget(covariant SubscribeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _log('🔁 didUpdateWidget userId changed ${oldWidget.userId} -> ${widget.userId}');
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
    _log('🧠 resolved seed state userId=${widget.userId} resolved=$resolvedState');
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

  Future<void> _handleTap(BuildContext context, bool isSubscribed) async {
    final optimisticStatus = !isSubscribed;
    _log(
      '👆 tap userId=${widget.userId} current=$isSubscribed optimistic=$optimisticStatus',
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
          'Failed to ${isSubscribed ? 'unsubscribe from' : 'subscribe to'} ${widget.username}';

      if (e.toString().contains('subscribe to yourself')) {
        errorMessage = 'You cannot subscribe to yourself';
      } else if (e.toString().contains('405') ||
          e.toString().contains('Method Not Allowed')) {
        errorMessage = 'Subscription service unavailable. Please try again later.';
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
    }
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

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => _handleTap(context, isSubscribed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 42,
              padding: const EdgeInsets.only(left: 2, right: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFD42BC2,
                          ).withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 18,
                      color: Color(0xFFD42BC2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: Text(
                      isSubscribed ? 'Subscribed' : 'Subscribe',
                      key: ValueKey(isSubscribed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
