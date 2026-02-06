import 'package:flutter/material.dart';

class PasswordInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<bool>? onVisibilityChanged;

  const PasswordInputField({
    super.key,
    this.controller,
    this.hintText = 'Enter your password',
    this.onVisibilityChanged,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF8B3FAE).withOpacity(0.18),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
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
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
              widget.onVisibilityChanged?.call(_obscurePassword);
            },
            child: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
