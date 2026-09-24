import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class MessageButton extends StatelessWidget {
  final VoidCallback onTap;

  const MessageButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: context.rh(44),
          padding: EdgeInsets.symmetric(horizontal: context.rw(18)),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFE24E0), width: 1.5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: context.rw(19),
                color: Colors.white,
              ),
              SizedBox(width: context.rw(7)),
              Text(
                'Message',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.rf(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
