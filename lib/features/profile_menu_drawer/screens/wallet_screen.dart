import 'package:flutter/material.dart';

import 'package:gruve_app/features/profile_menu_drawer/widgets/wallet_center_cart.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/wallet_diamond_stats_card.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/wallet_footer.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/wallet_header.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

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
            SizedBox(height: context.rh(22)),
            const WalletDiamondStatsCard(),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: context.rh(20)),
                  WalletCenterCart(
                    title: "Cheers",
                    buttonText: "Add cheers",
                    onTap: () {
                      AppLogger.d("Add Cheers button clicked");
                    },
                  ),
                  SizedBox(height: context.rh(20)),
                  WalletCenterCart(
                    title: "Mints",
                    buttonText: "Redeem",
                    onTap: () {
                      AppLogger.d("Add mints button clicked");
                    },
                  ),
                ],
              ),
            ),

            /// ===== FOOTER (Always Bottom) =====
            const WalletFooter(),
            SizedBox(height: context.rh(20)),
          ],
        ),
      ),
    );
  }
}
