import 'package:flutter/material.dart';

class ConfirmPasswordInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;

  const ConfirmPasswordInputField({
    super.key,
    this.controller,
    this.hintText = 'Confirm your password',
  });

  @override
  State<ConfirmPasswordInputField> createState() => _ConfirmPasswordInputFieldState();
}

class _ConfirmPasswordInputFieldState extends State<ConfirmPasswordInputField> {
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
