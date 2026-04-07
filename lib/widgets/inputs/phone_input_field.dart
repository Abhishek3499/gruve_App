import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final String? externalErrorText;

  const PhoneInputField({
    super.key,
    this.controller,
    this.focusNode,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.externalErrorText,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  Country selectedCountry = Country.parse('US');
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

  String get dialCode => '+${selectedCountry.phoneCode}';

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
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  showCountryPicker(
                    context: context,
                    onSelect: (country) {
                      setState(() => selectedCountry = country);
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Text(
                        selectedCountry.flagEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dialCode,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              Container(height: 28, width: 1, color: const Color(0xFFAF50C4)),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  keyboardType: TextInputType.phone,
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
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "(454) 726-0592",
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                    errorStyle: TextStyle(fontSize: 0, height: 0),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ],
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
