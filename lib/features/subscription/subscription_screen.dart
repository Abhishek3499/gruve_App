import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/subscription/widgets/subscription_header.dart';
import 'widgets/subscription_card.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14001A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const SubscriptionHeader(),

            // Subscription cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  // Basic Plan
                  SubscriptionCard(
                    iconPath: AppAssets.gold,
                    coins: 1000,
                    price: '\$9',
                    isSelected: true,
                    isLocked: false,
                    onTap: () {
                      // Handle basic plan selection
                    },
                  ),

                  // Premium Plan
                ],
              ),
            ),

            // Buy button
            // Padding(
            //   padding: const EdgeInsets.all(20),
            //   child: Container(
            //     width: double.infinity,
            //     height: 56,
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(28),
            //       gradient: const LinearGradient(
            //         begin: Alignment.topLeft,
            //         end: Alignment.bottomRight,
            //         colors: [Color(0xFF9B4CA9), Color(0xFF7B3F96)],
            //       ),
            //       boxShadow: [
            //         BoxShadow(
            //           color: const Color(0xFF9B4CA9).withOpacity(0.3),
            //           blurRadius: 12,
            //           offset: const Offset(0, 4),
            //         ),
            //       ],
            //     ),
            //     child: Material(
            //       color: Colors.transparent,
            //       child: InkWell(
            //         borderRadius: BorderRadius.circular(28),
            //         onTap: () {
            //           // Handle buy action
            //         },
            //         child: const Center(
            //           child: Text(
            //             'Buy Now',
            //             style: TextStyle(
            //               color: Colors.white,
            //               fontSize: 16,
            //               fontWeight: FontWeight.w600,
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
