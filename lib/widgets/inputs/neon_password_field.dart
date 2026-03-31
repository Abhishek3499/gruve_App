import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class NeonPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator; // ✅ ADD

  const NeonPasswordField({
    super.key,
    this.controller,
    this.hintText = 'Enter your password',
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator, // ✅ ADD
  });

  @override
  State<NeonPasswordField> createState() => _NeonPasswordFieldState();
}

class _NeonPasswordFieldState extends State<NeonPasswordField> {
  bool _obscurePassword = true;
  String? _errorText; // ✅ ADD
  late FocusNode _effectiveFocusNode; // ✅ ADD
  bool _hasBeenFocused = false; // ✅ ADD

  @override
  void initState() {
    super.initState();
    // ✅ Bahar se aaya toh use karo, warna apna banao
    _effectiveFocusNode = widget.focusNode ?? FocusNode();

    _effectiveFocusNode.addListener(() {
      // ✅ Focus GAYI tab validate karo
      if (!_effectiveFocusNode.hasFocus && _hasBeenFocused) {
        _validate();
      }
      if (_effectiveFocusNode.hasFocus) _hasBeenFocused = true;
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _effectiveFocusNode.dispose();
    super.dispose();
  }

  void _validate() {
    final error = widget.validator?.call(widget.controller?.text);
    if (mounted) setState(() => _errorText = error);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // ✅ Column — error bahar dikhega
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF461851),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _errorText != null
                  ? const Color(0xFFFF6B6B) // ✅ red border on error
                  : const Color(0xFFAF50C4),
              width: 1,
            ),
          ),
          child: TextFormField(
            // ✅ TextField → TextFormField
            controller: widget.controller,
            focusNode: _effectiveFocusNode,
            obscureText: _obscurePassword,
            obscuringCharacter: '*',
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            validator: (value) {
              final error = widget.validator?.call(value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _errorText = error);
              });
              return null; // ✅ andar mat dikhao
            },
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.white),
              border: InputBorder.none,
              errorStyle: const TextStyle(fontSize: 0, height: 0), // ✅ hide
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIconConstraints: const BoxConstraints(
                minHeight: 20,
                minWidth: 20,
              ),
              suffixIcon: GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility, // ✅ no asset needed
                    size: 22,
                    color: const Color(0x99FF00FF),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ✅ Error text field ke bahar
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _errorText != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, top: 5),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
