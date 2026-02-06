import 'package:flutter/material.dart';

class NeonTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const NeonTextField({
    super.key,
    this.controller,
    this.hintText = '',
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF461851),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFAF50C4),
          width: 1,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 20,
          ),
          const BoxShadow(
            color: Color(0xCC5C1B6D),
            offset: Offset(-8, -8),
            blurRadius: 20,
            spreadRadius: -1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white60),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: Colors.white70,
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }
}
