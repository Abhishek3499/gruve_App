import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class WalletCenterCart extends StatelessWidget {
  final String title;
  final String buttonText;
  final VoidCallback onTap;

  const WalletCenterCart({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF541067),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Left Section
          Row(
            children: [
              Image.asset(AppAssets.walletdiamond, width: 22, height: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          /// Right Button Section
          /// Right Button Section
          GestureDetector(
            onTap: onTap,
            child: Container(
              // 🔥 FIX: Fixed width dene se dono buttons ka size same ho jayega
              width: 120,
              alignment: Alignment.center, // Text ko center mein rakhne ke liye
              padding: const EdgeInsets.symmetric(
                vertical: 10,
              ), // Horizontal padding hata di kyunki width fixed hai
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color.fromARGB(255, 146, 57, 137),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
