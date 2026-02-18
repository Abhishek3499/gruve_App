import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SubscribeButton extends StatelessWidget {
  final bool isSubscribed;
  final VoidCallback onTap;

  const SubscribeButton({
    super.key,
    required this.isSubscribed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSubscribed
              ? const LinearGradient(
                  colors: [Colors.grey, Colors.grey],
                )
              : const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isSubscribed
                  ? Colors.grey.withOpacity(0.4)
                  : const Color(0xFF9C27B0).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSubscribed ? "Subscribed" : "Subscribe",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isSubscribed
                        ? Colors.grey.withOpacity(0.6)
                        : const Color(0xFF9C27B0).withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                isSubscribed ? Icons.check : Icons.add,
                size: 14,
                color: isSubscribed ? Colors.grey : const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
