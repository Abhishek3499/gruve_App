import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/privacy/constants/privacy_constants.dart';

import 'package:gruve_app/features/privacy/presentation/widgets/account_privacy_header.dart';
import 'package:gruve_app/features/privacy/presentation/widgets/privacy_card.dart';
import 'package:gruve_app/features/privacy/presentation/widgets/privacy_toggle_tile.dart';
import 'package:gruve_app/features/privacy/presentation/widgets/account_privacy_footer.dart';

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
          gradient: LinearGradient(
            begin: Alignment(0.8, -1.0),
            end: Alignment(-0.8, 1.0),
            colors: [Color(0xFF42174C), Color(0xFF210C26), Color(0xFF000000)],
            stops: [0.0, 0.3, 1.0],
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              const AccountPrivacyHeader(),
              SizedBox(height: context.rh(12)),

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
