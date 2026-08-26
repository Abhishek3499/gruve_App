import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/archive/domain/entities/archive_tab.dart';
import 'package:gruve_app/features/archive/presentation/widgets/archive_fav_tab.dart';
import 'package:gruve_app/features/archive/presentation/widgets/archive_header.dart';
import 'package:gruve_app/features/archive/presentation/widgets/archive_switcher_tab.dart';

import 'package:gruve_app/features/archive/presentation/widgets/archive_grid_view.dart';
import 'package:gruve_app/features/privacy/constants/privacy_constants.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  ArchiveTab _selectedTab = ArchiveTab.archive;

  void _onTabChanged(ArchiveTab tab) {
    setState(() {
      _selectedTab = tab;
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
              const ArchiveHeader(),
              SizedBox(height: context.rh(10)),

              ArchiveSwitcherTab(
                selectedTab: _selectedTab,
                onTabChanged: _onTabChanged,
              ),

              SizedBox(height: context.rh(20)),

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
