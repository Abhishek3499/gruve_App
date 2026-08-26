import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/help_center/presentation/widgets/help_center_header.dart';
import 'package:gruve_app/features/help_center/presentation/widgets/help_center_switcher_tab.dart';
import 'package:gruve_app/features/help_center/presentation/widgets/faq_tab.dart';
import 'package:gruve_app/features/help_center/presentation/widgets/contact_us_tab.dart';
import 'package:gruve_app/features/help_center/domain/entities/help_center_tab.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  HelpCenterTab selectedTab = HelpCenterTab.faq;

  void _onTabChanged(HelpCenterTab tab) {
    setState(() {
      selectedTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity, // Poori screen cover karne ke liye
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, // Gradient kahan se shuru hoga
            end: Alignment.bottomCenter, // Kahan khatam hoga
            colors: [
              Color.fromARGB(255, 57, 3, 69), // Dark Purple
              Color.fromARGB(255, 3, 0, 4), // Near Black
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const HelpCenterHeader(),
              SizedBox(height: context.rh(10)),
              HelpCenterSwitcherTab(
                selectedTab: selectedTab,
                onTabChanged: _onTabChanged,
              ),
              SizedBox(height: context.rh(20)),

              /// CONTENT AREA
              Expanded(
                child: selectedTab == HelpCenterTab.faq
                    ? const FaqTab()
                    : const ContactUsTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
