import 'package:flutter/material.dart';

class NeonPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;

  const NeonPasswordField({
    super.key,
    this.controller,
    this.hintText = 'Enter your password',
  });

  @override
  State<NeonPasswordField> createState() => _NeonPasswordFieldState();
}

class _NeonPasswordFieldState extends State<NeonPasswordField> {
  bool _obscurePassword = true;

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
        controller: widget.controller,
        obscureText: _obscurePassword,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.white60),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            child: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
