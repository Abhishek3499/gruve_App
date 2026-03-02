import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/models/archive_model/archive_tab.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/Archive/archive_fav_tab.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/Archive/archive_header.dart';
import 'package:gruve_app/features/profile_menu_drawer/widgets/Archive/archive_switcher_tab.dart';

import 'package:gruve_app/features/profile_menu_drawer/widgets/Archive/archive_grid_view.dart';
import '../../constants/privacy_constants.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  ArchiveTab _selectedTab = ArchiveTab.archive;

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
              const ArchiveHeader(),
              const SizedBox(height: 10),

              ArchiveSwitcherTab(
                selectedTab: _selectedTab,
                onTabChanged: (tab) {
                  setState(() {
                    _selectedTab = tab;
                  });
                },
              ),

              const SizedBox(height: 20),

              Expanded(
                child: _selectedTab == ArchiveTab.archive
                    ? const ArchiveGridView()
                    : const ArchiveFavTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
