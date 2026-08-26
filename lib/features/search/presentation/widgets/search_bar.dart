import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color backgroundColor;
  final Border? border;
  final Gradient? borderGradient;
  final Gradient? backgroundGradient;
  final double borderWidth;
  final double borderRadius;
  final double height;
  final double? width;
  final EdgeInsetsGeometry contentPadding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final bool readOnly;
  final bool autofocus;
  final TextInputAction textInputAction;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Search Users, Hashtags',
    this.prefixIcon = const Icon(Icons.search, color: Colors.white),
    this.suffixIcon,
    this.backgroundColor = const Color(0xFF7A1FA2),
    this.border,
    this.borderGradient = const LinearGradient(
      colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
    ),
    this.backgroundGradient,
    this.borderWidth = 2,
    this.borderRadius = 30,
    this.height = 50,
    this.width,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 14),
    this.textStyle,
    this.hintStyle,
    this.readOnly = false,
    this.autofocus = false,
    this.textInputAction = TextInputAction.search,
  });

  @override
  Widget build(BuildContext context) {
    final innerRadius = (borderRadius - borderWidth).clamp(0, borderRadius);

    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
          gradient: borderGradient,
        ),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(innerRadius.toDouble()),
            color: backgroundGradient == null ? backgroundColor : null,
            gradient: backgroundGradient,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onTap: onTap,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            readOnly: readOnly,
            autofocus: autofocus,
            textInputAction: textInputAction,
            style: textStyle ?? const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              hintText: hintText,
              hintStyle: hintStyle ?? const TextStyle(color: Colors.white),
              contentPadding: contentPadding,
            ),
          ),
        ),
      ),
    );
  }
}
