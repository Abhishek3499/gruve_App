import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class GiftButton extends StatelessWidget {
  const GiftButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint("Gift button clicked 🎁");
      },
      child: SizedBox(
        width: 25,
        height: 25,
        child: Image.asset(AppAssets.gifticon2, fit: BoxFit.contain),
      ),
    );
  }
}
