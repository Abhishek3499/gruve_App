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

        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: hasValue
                ? const Color(0xFFB86AD0)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22), // ✅ perfect shape
            border: Border.all(
              color: hasValue ? Colors.transparent : Colors.white,
              width: 1.5,
            ),
          ),
          child: Center(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autoFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              showCursor: false,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none, // ✅ IMPORTANT
                hintText: '-',
                hintStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onChanged: (val) {
                if (val.isNotEmpty) {
                  onChanged?.call(val);
                } else {
                  onBackspace?.call();
                }
              },
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        );
      },
    );
  }
}
