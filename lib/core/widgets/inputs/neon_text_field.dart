import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NeonTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final String? errorText;

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
    this.onChanged,
    this.validator,
    this.errorText,
  });

  @override
  State<NeonTextField> createState() => _NeonTextFieldState();
}

class _NeonTextFieldState extends State<NeonTextField> {
  String? _errorText;
  late FocusNode _effectiveFocusNode;
  bool _hasBeenFocused = false; // ✅ track karo ki user aaya tha ya nahi

  @override
  void initState() {
    super.initState();
    // ✅ Agar bahar se focusNode aaya toh use karo, warna apna banao
    _effectiveFocusNode = widget.focusNode ?? FocusNode();

    _effectiveFocusNode.addListener(() {
      // ✅ Jab focus CHALI JAAYE (user next field mein gaya) tab validate karo
      if (!_effectiveFocusNode.hasFocus && _hasBeenFocused) {
        _validate();
      }
      if (_effectiveFocusNode.hasFocus) {
        _hasBeenFocused = true;
      }
    });
  }

  @override
  void dispose() {
    // ✅ Sirf apna wala dispose karo
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    }
    super.dispose();
  }

  void _validate() {
    final error = widget.validator?.call(widget.controller?.text);
    if (mounted) setState(() => _errorText = error);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmailField = widget.keyboardType == TextInputType.emailAddress;
    final effectiveErrorText = widget.errorText ?? _errorText;
    const fieldIconColor = Color(0x99FF00FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF461851),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: effectiveErrorText != null
                  ? const Color(0xFFFF6B6B) // ❌ red border on error
                  : const Color(0xFFAF50C4), // ✅ normal border
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _effectiveFocusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
            inputFormatters: isEmailField
                ? [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9@._+-]'),
                    ),
                  ]
                : null,
            validator: widget.validator == null
                ? null
                : (value) {
                    final error = widget.validator?.call(value);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _errorText = error);
                    });
                    return null; // andar mat dikhao
                  },
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
              border: InputBorder.none,
              errorStyle: const TextStyle(fontSize: 0, height: 0), // hide
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 20,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Image.asset(
                        widget.prefixIcon!,
                        width: 22,
                        height: 22,
                        color: fieldIconColor,
                      ),
                    )
                  : widget.obscureText
                  ? const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Icon(
                        Icons.lock_outline,
                        size: 21,
                        color: fieldIconColor,
                      ),
                    )
                  : null,
            ),
          ),
        ),

        // ✅ Error text field ke bahar
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: effectiveErrorText != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, top: 5),
                  child: Text(
                    effectiveErrorText,
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
