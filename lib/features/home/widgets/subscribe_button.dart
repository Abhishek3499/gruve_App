import 'package:flutter/material.dart';
import '../controllers/subscribe_controller.dart';
import '../models/subscribe_model.dart';

class SubscribeButton extends StatefulWidget {
  final String userId;
  final String username;
  final SubscribeController subscribeController;

  const SubscribeButton({
    super.key,
    required this.userId,
    required this.username,
    required this.subscribeController,
  });

  @override
  State<SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<SubscribeButton> {
  @override
  void initState() {
    super.initState();
    // Initialize user if not already done
    if (widget.subscribeController.getUserSubscribeModel(widget.userId) == null) {
      widget.subscribeController.addOrUpdateUser(
        SubscribeModel(
          userId: widget.userId,
          username: widget.username,
          isSubscribed: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.subscribeController,
      builder: (context, child) {
        final isSubscribed = widget.subscribeController.isUserSubscribed(widget.userId);
        
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
              try {
                final newSubscriptionStatus = await widget.subscribeController.toggleSubscription(widget.userId);
                
                // Securely check context mounted state to prevent deactivated widget lookup crash
                if (!context.mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      newSubscriptionStatus ? 'Subscribed to ${widget.username}' 
                                         : 'Unsubscribed from ${widget.username}',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                print("❌ SUBSCRIPTION BUTTON ERROR: $e");
                
                if (!context.mounted) return;

                String errorMessage = 'Failed to ${isSubscribed ? 'unsubscribe from' : 'subscribe to'} ${widget.username}';
                
                if (e.toString().contains('subscribe to yourself')) {
                  errorMessage = 'You cannot subscribe to yourself';
                } else if (e.toString().contains('405') || e.toString().contains('Method Not Allowed')) {
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
              }
            },
            child: Text(
              isSubscribed ? "Subscribed" : "Subscribe",
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
