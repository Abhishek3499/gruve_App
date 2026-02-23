import 'package:flutter/material.dart';
import 'package:gruve_app/features/views/screens/views_screen.dart';

import '../../../../core/assets.dart';
import '../widgets/insight_list_tile.dart';
import '../widgets/insight_footer.dart';

class ProfessionalDashboardScreen extends StatelessWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9544A7), Color(0xFF42174C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// 🔥 HEADER
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    /// Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              AppAssets.back,
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Title
                    const Text(
                      "Professional Dashboard",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'syncopate',
                      ),
                    ),
                  ],
                ),
              ),

              /// 🔥 BODY SECTION
              Expanded(
                child: Column(
                  children: [
                    /// Scrollable List
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(top: 20),
                        children: [
                          InsightListTile(
                            title: "Views",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),

                          InsightListTile(title: "Interactions", onTap: () {}),
                          const SizedBox(height: 10),

                          InsightListTile(
                            title: "Top Performing Reel",
                            onTap: () {},
                          ),
                          const SizedBox(height: 10),

                          InsightListTile(title: "Activity", onTap: () {}),
                        ],
                      ),
                    ),

                    /// Footer (Fixed Bottom)
                    const InsightFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
