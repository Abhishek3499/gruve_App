import 'package:flutter/material.dart';
import 'package:gruve_app/features/privacy/constants/privacy_constants.dart';

class PrivacyToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PrivacyToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// TITLE
        Expanded(child: Text(title, style: PrivacyConstants.titleStyle)),

        const SizedBox(width: 10),

        /// RIGHT SWITCH
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFFB44DFF),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFF5A4A63),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}
