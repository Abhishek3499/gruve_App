import 'package:flutter/material.dart';

import '../controllers/subscribe_controller.dart';
import '../models/subscribe_model.dart';

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
    debugPrint('🎬 [HomeSubscribeButton] $message');
  }

  @override
  void initState() {
    super.initState();
    _log(
      '🛠️ initState userId=${widget.userId} username=${widget.username} initial=${widget.initialIsSubscribed}',
    );
    if (widget.subscribeController.getUserSubscribeModel(widget.userId) ==
        null) {
      _log('🧱 no local model found, seeding initial state');
      widget.subscribeController.addOrUpdateUser(
        SubscribeModel(
          userId: widget.userId,
          username: widget.username,
          isSubscribed: widget.initialIsSubscribed,
        ),
      );
    } else {
      _log(
        '📦 existing local model already present for userId=${widget.userId}',
      );
    }
  }

  void _showSubscriptionSnackBar(bool isSubscribed) {
    _log('🍞 show snackbar state=$isSubscribed userId=${widget.userId}');
    if (!context.mounted) return;
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

        return SizedBox(
          height: 32,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              backgroundColor: isSubscribed ? Colors.white : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () async {
              final optimisticStatus = !isSubscribed;
              _log(
                '👆 tap userId=${widget.userId} current=$isSubscribed optimistic=$optimisticStatus',
              );
              _showSubscriptionSnackBar(optimisticStatus);

              try {
                final result = await widget.subscribeController
                    .toggleSubscription(widget.userId);
                _log(
                  '✅ toggleSubscription future resolved userId=${widget.userId} result=$result',
                );
              } catch (e) {
                _log('❌ button error userId=${widget.userId} error=$e');

                if (!context.mounted) return;

                String errorMessage =
                    'Failed to ${isSubscribed ? 'unsubscribe from' : 'subscribe to'} ${widget.username}';

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
              }
            },
            child: Text(
              isSubscribed ? 'Subscribed' : 'Subscribe',
              style: TextStyle(
                color: isSubscribed ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
