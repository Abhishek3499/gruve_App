import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autoFocus;
  final Function(String)? onChanged;
  final Function()? onBackspace;

  const OtpInputBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.autoFocus = false,
    this.onChanged,
    this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasValue = value.text.isNotEmpty;

        return SizedBox(
          width: 45,
          height: 55,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autoFocus,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '-',
              hintStyle: const TextStyle(
                color: Colors.white38,
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withAlpha(8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFB86AD0)),
              ),
              filled: true,
              fillColor: hasValue
                  ? const Color(0xFF9544A7)
                  : Colors.white.withAlpha(20),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && RegExp(r'^[0-9]$').hasMatch(value)) {
                onChanged?.call(value);
              } else if (value.isEmpty) {
                onBackspace?.call();
              }
            },
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        );
      },
    );
  }
}
