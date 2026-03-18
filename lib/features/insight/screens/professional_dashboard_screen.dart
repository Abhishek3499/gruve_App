import 'package:flutter/material.dart';
import 'package:gruve_app/features/activity/screens/activity_screen.dart';
import 'package:gruve_app/features/interactions/screens/interactions_screen.dart';
import 'package:gruve_app/features/top_performance_Reel/performance_screen.dart';
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
              /// 🔥 FIXED HEADER (Stack hata kar Row lagaya hai)
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  // 👈 Stack ki jagah Row use kiya for perfect alignment
                  children: [
                    /// Back Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context),
                        splashColor: Colors.transparent, // ❌ No white splash
                        highlightColor:
                            Colors.transparent, // ❌ No click highlight
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              AppAssets.back,
                              width: 25,
                              height: 25,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// 🔥 GAP (Back button aur Text ke beech)
                    const SizedBox(width: 15),

                    /// Title
                    const Expanded(
                      child: Text(
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
                    ),
                  ],
                ),
              ),

              /// 🔥 BODY SECTION (Same as before)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(top: 20),
                        children: [
                          InsightListTile(
                            title: "Views",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ViewsScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InsightListTile(
                            title: "Interactions",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const InteractionsScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InsightListTile(
                            title: "Top Performing Reel",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PerformanceScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InsightListTile(
                            title: "Activity",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ActivityScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
