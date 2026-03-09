import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class MoreHeader extends StatelessWidget {
  final VoidCallback onBack;

  const MoreHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 10),
        child: InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 36,
            width: 36,
            child: Center(child: Image.asset(AppAssets.back, width: 28)),
          ),
        ),
      ),
    );
  }
}
