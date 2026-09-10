import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps a single OTP box to exactly one digit during normal typing, while
/// still allowing a full multi-digit burst (paste or SMS autofill) to pass
/// through untouched so the parent can distribute it across the other boxes.
///
/// Without this, each box's [TextField] could accumulate more than one
/// character (e.g. when a keystroke lands before focus finishes moving to
/// the next box), which made the parent's paste-distribution logic run on
/// ordinary typing and jump focus to the wrong field.
class _OtpDigitInputFormatter extends TextInputFormatter {
  const _OtpDigitInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newDigits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (newDigits.length <= 1) {
      return TextEditingValue(
        text: newDigits,
        selection: TextSelection.collapsed(offset: newDigits.length),
      );
    }

    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    final addedDigits = newDigits.length - oldDigits.length;

    if (addedDigits > 1) {
      // A bulk insert (paste / autofill) — pass the full burst through.
      return TextEditingValue(
        text: newDigits,
        selection: TextSelection.collapsed(offset: newDigits.length),
      );
    }

    // A single keystroke landed on top of an existing digit; keep only the
    // latest digit instead of letting this box accumulate characters.
    final latest = newDigits.substring(newDigits.length - 1);
    return TextEditingValue(
      text: latest,
      selection: TextSelection.collapsed(offset: latest.length),
    );
  }
}

class OtpInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autoFocus;
  final bool enableSmsAutofill;
  final Function(String)? onChanged;
  final Function()? onBackspace;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const OtpInputBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.autoFocus = false,
    this.enableSmsAutofill = false,
    this.onChanged,
    this.onBackspace,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasValue = value.text.isNotEmpty;

        return GestureDetector(
          onTap: () => focusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Container(
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
            child: Focus(
              onKeyEvent: (node, event) {
                if (event.logicalKey == LogicalKeyboardKey.backspace &&
                    controller.text.isEmpty) {
                  onBackspace?.call();
                }
                return KeyEventResult.ignored;
              },
              child: Center(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: autoFocus,
                  keyboardType: TextInputType.number,
                  textInputAction: textInputAction ?? TextInputAction.next,
                  onSubmitted: onSubmitted,
                  autofillHints: enableSmsAutofill
                      ? const [AutofillHints.oneTimeCode]
                      : null,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  showCursor: false,
                  onTap: () {
                    controller.selection = TextSelection.collapsed(
                      offset: controller.text.length,
                    );
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none, // ✅ IMPORTANT
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
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
                  inputFormatters: const [_OtpDigitInputFormatter()],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
