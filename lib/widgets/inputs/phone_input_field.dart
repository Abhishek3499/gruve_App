import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController? controller;

  const PhoneInputField({super.key, this.controller});

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  Country selectedCountry = Country.parse('US');

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF461851),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFAF50C4)),
      ),
      child: Row(
        children: [
          /// COUNTRY PICKER
          GestureDetector(
            onTap: () {
              showCountryPicker(
                context: context,
                onSelect: (country) {
                  setState(() {
                    selectedCountry = country;
                  });
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
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          /// DIVIDER
          Container(height: 28, width: 1, color: const Color(0xFFAF50C4)),

          /// PHONE TEXTFIELD
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "(454) 726-0592",
                hintStyle: TextStyle(color: Colors.white60),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
