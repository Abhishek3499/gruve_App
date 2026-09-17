import 'package:flutter/material.dart';

import 'package:gruve_app/features/home/presentation/controllers/subscribe_notifier.dart';
import 'package:gruve_app/features/home/data/models/subscribe_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class SubscribeButton extends StatefulWidget {
  final String userId;
  final String username;
  final SubscribeNotifier subscribeController;
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
  bool _isProcessing = false;

  void _log(String message) {
    AppLogger.d('🎬 [HomeSubscribeButton] $message');
  }

  @override
  void initState() {
    super.initState();
    if (widget.subscribeController.getUserSubscribeModel(widget.userId) ==
        null) {
      widget.subscribeController.addOrUpdateUser(
        SubscribeModel(
          userId: widget.userId,
          username: widget.username,
          isSubscribed: widget.initialIsSubscribed,
        ),
      );
    }
  }

  void _showSubscriptionSnackBar(bool isSubscribed) {
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
            onPressed: _isProcessing
                ? null
                : () async {
                    final optimisticStatus = !isSubscribed;
              _showSubscriptionSnackBar(optimisticStatus);

              setState(() {
                _isProcessing = true;
              });

              try {
                await widget.subscribeController
                    .toggleSubscription(widget.userId);
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
              } finally {
                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                  });
                }
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
