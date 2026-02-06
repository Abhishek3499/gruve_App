import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFFFFFFF), thickness: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or continue with ',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 14,
              fontFamily: AppAssets.montserratfont,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFFFFFFF), thickness: 1)),
      ],
    );
  }
}
