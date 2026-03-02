import 'package:flutter/material.dart';
import '../constants/privacy_constants.dart';

import '../widgets/account_privacy_header.dart';
import '../widgets/privacy_card.dart';
import '../widgets/privacy_toggle_tile.dart';
import '../widgets/account_privacy_footer.dart';

class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({super.key});

  @override
  State<AccountPrivacyScreen> createState() => _AccountPrivacyScreenState();
}

class _AccountPrivacyScreenState extends State<AccountPrivacyScreen> {
  late List<bool> _toggleValues;

  @override
  void initState() {
    super.initState();
    _toggleValues = PrivacyConstants.privacyOptions
        .map((option) => option.isEnabled)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: PrivacyConstants.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const AccountPrivacyHeader(),
              SizedBox(height: 12),

              PrivacyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    ...PrivacyConstants.privacyOptions.asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final option = entry.value;
                      return PrivacyToggleTile(
                        title: option.title,
                        description: option.description,
                        value: _toggleValues[index],
                        onChanged: (newValue) {
                          setState(() {
                            _toggleValues[index] = newValue;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              Spacer(),
              const AccountPrivacyFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
