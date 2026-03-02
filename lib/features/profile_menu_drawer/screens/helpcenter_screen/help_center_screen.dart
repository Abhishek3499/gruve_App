import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/Helpcenter/Help_center_header.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/Helpcenter/Help_center_switcher_tab.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/Helpcenter/faq_tab.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/Helpcenter/contact_us_tab.dart';
import 'package:gruve_app/features/profile_menu_drawer/models/help_center_tab.dart';
import '../../constants/privacy_constants.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  HelpCenterTab selectedTab = HelpCenterTab.faq;

  void _onTabChanged(HelpCenterTab tab) {
    debugPrint('Tab changed to: $tab'); // Debug print
    setState(() {
      selectedTab = tab;
      debugPrint('Selected tab updated to: $selectedTab'); // Debug print
    });
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
              const HelpCenterHeader(),
              const SizedBox(height: 10),
              HelpCenterSwitcherTab(
                selectedTab: selectedTab,
                onTabChanged: _onTabChanged,
              ),
              SizedBox(height: 20),

              /// CONTENT AREA
              Expanded(
                child: () {
                  debugPrint('Displaying tab: $selectedTab'); // Debug print
                  return selectedTab == HelpCenterTab.faq
                      ? const FaqTab()
                      : const ContactUsTab();
                }(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
