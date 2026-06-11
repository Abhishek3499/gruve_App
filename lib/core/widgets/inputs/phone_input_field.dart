import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator; // ✅
  final String? errorText;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;

  const PhoneInputField({
    super.key,
    this.controller,
    this.focusNode,
    this.validator,
    this.errorText,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  static const int _indiaPhoneDigits = 10;
  static const int _internationalPhoneDigits = 15;

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
  int get _maxPhoneDigits => selectedCountry.countryCode == 'IN'
      ? _indiaPhoneDigits
      : _internationalPhoneDigits;

  void _trimPhoneToCountryLimit() {
    final controller = widget.controller;
    if (controller == null) return;

    final limitedText = _limitPhoneDigits(controller.text, _maxPhoneDigits);
    if (limitedText == controller.text) return;

    controller.value = TextEditingValue(
      text: limitedText,
      selection: TextSelection.collapsed(offset: limitedText.length),
    );
  }

  String _getHintText() {
    switch (selectedCountry.countryCode) {
      case 'IN':
        return "98765 43210";
      case 'US':
      case 'CA':
        return "(454) 726-0592";
      case 'GB':
        return "7911 123456";
      case 'SG':
        return "9123 4567";
      case 'AE':
        return "50 123 4567";
      case 'AU':
        return "412 345 678";
      default:
        if (_maxPhoneDigits == 10) {
          return "98765 43210";
        } else if (_maxPhoneDigits == 8) {
          return "8123 4567";
        } else if (_maxPhoneDigits == 9) {
          return "912 345 678";
        } else {
          return "12345 67890";
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveErrorText = widget.errorText ?? _errorText;

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
              color: effectiveErrorText != null
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFFB86AD0),
              width: 1.2,
            ),

            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB86AD0).withValues(alpha: 0.25),
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
                  // Dismiss keyboard first to avoid modal layout animation jank/lag
                  FocusScope.of(context).unfocus();

                  showCountryPicker(
                    context: context,
                    favorite: const <String>['IN', 'US', 'GB'],
                    countryListTheme: CountryListThemeData(
                      backgroundColor: const Color(0xFF2A0D33),
                      textStyle: const TextStyle(color: Colors.white, fontSize: 15),
                      searchTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
                      inputDecoration: InputDecoration(
                        hintText: 'Search country',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFB86AD0)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFB86AD0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFB86AD0), width: 1.5),
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    onSelect: (country) {
                      setState(() => selectedCountry = country);
                      _trimPhoneToCountryLimit();
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
                color: const Color(0xFFB86AD0).withValues(alpha: 0.6),
              ),

              // ── PHONE INPUT ──────────────────────────────
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    _MaxPhoneDigitsInputFormatter(_maxPhoneDigits),
                  ],
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: widget.onFieldSubmitted,
                  validator: widget.validator == null
                      ? null
                      : (value) {
                          final error = widget.validator?.call(value);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _errorText = error);
                          });
                          return null; // andar mat dikhao
                        },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _getHintText(),
                    hintStyle: const TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                    errorStyle: const TextStyle(fontSize: 0, height: 0),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ✅ Error bahar
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

class _MaxPhoneDigitsInputFormatter extends TextInputFormatter {
  final int maxDigits;

  const _MaxPhoneDigitsInputFormatter(this.maxDigits);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final limitedText = _limitPhoneDigits(newValue.text, maxDigits);
    if (limitedText == newValue.text) return newValue;

    return TextEditingValue(
      text: limitedText,
      selection: TextSelection.collapsed(offset: limitedText.length),
    );
  }
}

String _limitPhoneDigits(String text, int maxDigits) {
  final buffer = StringBuffer();
  var digitCount = 0;

  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (RegExp(r'\d').hasMatch(char)) {
      if (digitCount >= maxDigits) continue;
      digitCount++;
    }
    buffer.write(char);
  }

  return buffer.toString();
}
