import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/wallet_DiamondStatsCard.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/wallet_center_cart.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/wallet_footer.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/wallet_header.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14001A),
      body: SafeArea(
        child: Column(
          children: [
            /// ===== TOP CONTENT =====
            const WalletHeader(),
            const SizedBox(height: 22),
            const WalletDiamondStatsCard(),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20),
                  WalletCenterCart(
                    title: "Cheers",
                    buttonText: "Add cheers",
                    onTap: () {
                      debugPrint("Add Cheers button clicked");
                    },
                  ),
                  const SizedBox(height: 20),
                  WalletCenterCart(
                    title: "Mints",
                    buttonText: "Redeem",
                    onTap: () {
                      debugPrint("Add mints button clicked");
                    },
                  ),
                ],
              ),
            ),

            /// ===== FOOTER (Always Bottom) =====
            const WalletFooter(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
