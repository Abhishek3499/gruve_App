import 'package:flutter/material.dart';
import 'package:gruve_app/features/home/presentation/controllers/subscribe_notifier.dart';
import 'package:gruve_app/features/home/data/models/subscribe_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

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
    AppLogger.d('🪪 [ProfileSubscribeButton] $message');
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
    if (_isProcessing) return;

    final optimisticStatus = !currentStatus;
    _log(
      '🔄 toggle userId=${widget.userId} current=$currentStatus optimistic=$optimisticStatus',
    );
    _showSubscriptionSnackBar(optimisticStatus);

    setState(() {
      _isProcessing = true;
    });

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
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildSubscribeWidget(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _performToggle(context, false),
        child: Container(
          width: context.rw(150),
          height: context.rh(44),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFFE24E0), Color(0xFF72008D)],
            ),
            borderRadius: BorderRadius.circular(22),
            // boxShadow: [
            //   BoxShadow(
            //     color: const Color(0xFFFE24E0).withValues(alpha: 0.4),
            //     offset: const Offset(0, 4),
            //     blurRadius: 10,
            //   ),
            // ],
          ),
          child: Center(
            child: Text(
              'Subscribe',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.rf(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscribedWidget(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _performToggle(context, true),
        child: Container(
          width: context.rw(140),
          height: context.rh(44),
          decoration: BoxDecoration(
            color: const Color(0xFF33123B).withValues(alpha: 0.6),
            border: Border.all(color: const Color(0xFFFE24E0), width: 1.5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              'Subscribed',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.rf(14),
                fontWeight: FontWeight.w600,
              ),
            ),
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

        return AnimatedOpacity(
          opacity: _isProcessing ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.95,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: isSubscribed
                ? _buildSubscribedWidget(context)
                : _buildSubscribeWidget(context),
          ),
        );
      },
    );
  }
}
