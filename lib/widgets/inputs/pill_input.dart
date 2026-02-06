import 'package:flutter/material.dart';

class PillInput extends StatelessWidget {
  final String hint;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType keyboardType;
  final bool obscure;

  const PillInput({
    super.key,
    required this.hint,
    this.prefix,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
  });

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
          if (prefix != null) ...[prefix!, const SizedBox(width: 12)],
          Expanded(
            child: TextField(
              keyboardType: keyboardType,
              obscureText: obscure,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white60),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffix != null) ...[const SizedBox(width: 12), suffix!],
        ],
      ),
    );
  }
}
