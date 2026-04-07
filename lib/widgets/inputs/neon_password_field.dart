import 'package:flutter/material.dart';

class NeonPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final String? externalErrorText;

  const NeonPasswordField({
    super.key,
    this.controller,
    this.hintText = 'Enter your password',
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
    this.onChanged,
    this.externalErrorText,
  });

  @override
  State<NeonPasswordField> createState() => _NeonPasswordFieldState();
}

class _NeonPasswordFieldState extends State<NeonPasswordField> {
  bool _obscurePassword = true;
  String? _errorText;
  late FocusNode _effectiveFocusNode;
  bool _hasBeenFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode = widget.focusNode ?? FocusNode();

    _effectiveFocusNode.addListener(() {
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
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    }
    super.dispose();
  }

  void _validate() {
    final error = widget.validator?.call(widget.controller?.text);
    if (mounted) {
      setState(() => _errorText = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveErrorText = widget.externalErrorText ?? _errorText;

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
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFFAF50C4),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _effectiveFocusNode,
            obscureText: _obscurePassword,
            obscuringCharacter: '*',
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            onChanged: (value) {
              widget.onChanged?.call(value);
              if (_hasBeenFocused) {
                _validate();
              }
            },
            validator: (value) {
              final error = widget.validator?.call(value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _errorText = error);
                }
              });
              return null;
            },
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.white),
              border: InputBorder.none,
              errorStyle: const TextStyle(fontSize: 0, height: 0),
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
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 22,
                    color: const Color(0x99FF00FF),
                  ),
                ),
              ),
            ),
          ),
        ),
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
