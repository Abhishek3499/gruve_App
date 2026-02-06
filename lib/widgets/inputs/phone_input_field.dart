import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

class PhoneInputField extends StatefulWidget {
  final Country country;
  final ValueChanged<Country> onCountryChanged;
  final TextEditingController? controller;
  final String hintText;

  const PhoneInputField({
    super.key,
    required this.country,
    required this.onCountryChanged,
    this.controller,
    this.hintText = '',
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF8B3FAE).withAlpha(46),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withAlpha(46), width: 1),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showCountryPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Row(
                children: [
                  Text(widget.country.flagEmoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hintText.isEmpty 
                    ? '${widget.country.phoneCode} (454) 726-0592'
                    : widget.hintText,
                hintStyle: const TextStyle(color: Colors.white60),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: widget.onCountryChanged,
      countryListTheme: CountryListThemeData(
        backgroundColor: const Color(0xFF1E1E2E),
        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
        searchTextStyle: const TextStyle(color: Colors.white),
        inputDecoration: InputDecoration(
          hintText: 'Search country...',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFB86AD0)),
          ),
        ),
        bottomSheetHeight: 600,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }
}
