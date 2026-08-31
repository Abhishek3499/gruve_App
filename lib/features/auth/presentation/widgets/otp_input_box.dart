import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                  maxLength: 4,
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
