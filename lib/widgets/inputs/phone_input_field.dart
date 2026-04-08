import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator; // ✅
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;

  const PhoneInputField({
    super.key,
    this.controller,
    this.focusNode,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
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

  String get dialCode => '+${selectedCountry.phoneCode}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),

            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF43184D), // 🔥 exact figma color
                Color(0xFF2A0D33),
              ],
            ),

            border: Border.all(
              color: _errorText != null
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFFB86AD0),
              width: 1.2,
            ),

            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB86AD0).withOpacity(0.25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // ── COUNTRY PICKER ──────────────────────────
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
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

              // ── DIVIDER ─────────────────────────────────
              Container(
                height: 30,
                width: 1.2,
                color: const Color(0xFFB86AD0).withOpacity(0.6),
              ),

              // ── PHONE INPUT ──────────────────────────────
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: widget.onFieldSubmitted,
                  validator: (value) {
                    final error = widget.validator?.call(value);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _errorText = error);
                    });
                    return null; // andar mat dikhao
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

        // ✅ Error bahar
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
