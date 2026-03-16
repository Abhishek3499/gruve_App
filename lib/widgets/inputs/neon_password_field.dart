import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class NeonPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;

  const NeonPasswordField({
    super.key,
    this.controller,
    this.hintText = 'Enter your password',
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
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
        border: Border.all(color: const Color(0xFFAF50C4), width: 1),
        // boxShadow: [
        //   const BoxShadow(
        //     color: Color(0x40000000),
        //     offset: Offset(0, 4),
        //     blurRadius: 20,
        //   ),
        //   const BoxShadow(
        //     color: Color(0xCC5C1B6D),
        //     offset: Offset(-8, -8),
        //     blurRadius: 20,
        //     spreadRadius: -1,
        //   ),
        // ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: _obscurePassword,
        obscuringCharacter: '*',
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onFieldSubmitted,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          suffixIconConstraints: const BoxConstraints(
            minHeight: 20,
            minWidth: 20,
          ),

          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Image.asset(
                _obscurePassword ? AppAssets.eyeoff : AppAssets.eyeoff,
                width: 27,
                height: 27,
                color: const Color(0x99FF00FF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
