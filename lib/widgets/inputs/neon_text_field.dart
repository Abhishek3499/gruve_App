import 'package:flutter/material.dart';

class NeonTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;

  const NeonTextField({
    super.key,
    this.controller,
    this.hintText = '',
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmailField = keyboardType == TextInputType.emailAddress;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF461851),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFAF50C4), width: 1),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onFieldSubmitted,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            // 👇 underline only for email
            decoration: isEmailField
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Image.asset(
                    prefixIcon!,
                    width: 22,
                    height: 22,
                    color: const Color(0x99FF00FF),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
