import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/Helpcenter/Help_center_header.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/Helpcenter/Help_center_switcher_tab.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/Helpcenter/contact_us_tab.dart';
import '../../constants/privacy_constants.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(0, 237, 7, 65),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: PrivacyConstants.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const HelpCenterHeader(),
              const SizedBox(height: 10),
              const HelpCenterSwitcherTab(),

              Expanded(child: ContactUsTab()),

              /// CONTENT AREA
            ],
          ),
        ),
      ),
    );
  }
}
