import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/subscription/widgets/subscription_header.dart';
import 'package:gruve_app/widgets/get_started_button.dart';
import 'widgets/subscription_card.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int? _selectedCardIndex;

  void _selectCard(int index) {
    setState(() {
      _selectedCardIndex = index;
    });
  }

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
                    isSelected: _selectedCardIndex == 0,
                    isLocked: false,
                    onTap: () => _selectCard(0),
                  ),
                  SubscriptionCard(
                    iconPath: AppAssets.gold,
                    coins: 90,
                    price: '\$29',
                    isSelected: _selectedCardIndex == 1,
                    isLocked: false,
                    onTap: () => _selectCard(1),
                  ),
                  SubscriptionCard(
                    iconPath: AppAssets.gold,
                    coins: 900,
                    price: '\$290',
                    isSelected: _selectedCardIndex == 2,
                    isLocked: false,
                    onTap: () => _selectCard(2),
                  ),
                  SubscriptionCard(
                    iconPath: AppAssets.gold,
                    centerImage: AppAssets.lock,
                    coins: 1000,
                    price: '\$9',
                    isSelected: _selectedCardIndex == 3,
                    isLocked: false,
                    onTap: () => _selectCard(3),
                  ),
                  SubscriptionCard(
                    iconPath: AppAssets.gold,
                    centerImage: AppAssets.lock,
                    coins: 10000,
                    price: '\$19',
                    isSelected: _selectedCardIndex == 4,
                    isLocked: false,
                    onTap: () => _selectCard(4),
                  ),

                  // Premium Plan
                ],
              ),
            ),

            // Buy button
            Padding(
              padding: const EdgeInsets.all(20),
              child: GetStartedButton(
                text: 'Buy',
                onComplete: () async {
                  // Handle buy action
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
