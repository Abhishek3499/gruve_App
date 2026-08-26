import 'package:flutter/material.dart';
import 'package:gruve_app/features/activity/screens/activity_screen.dart';
import 'package:gruve_app/features/interactions/screens/interactions_screen.dart';
import 'package:gruve_app/features/top_performance_Reel/performance_screen.dart';
import 'package:gruve_app/features/views/screens/views_screen.dart';

import '../widgets/insight_list_tile.dart';
import '../widgets/insight_footer.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

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
                height: context.rh(70),
                padding: EdgeInsets.symmetric(horizontal: context.rw(20)),
                child: Row(
                  // 👈 Stack ki jagah Row use kiya for perfect alignment
                  children: [
                    BackButton(
                      color: Colors.white,
                      onPressed: () => Navigator.pop(context),
                    ),

                    /// 🔥 GAP (Back button aur Text ke beech)
                    SizedBox(width: context.rw(15)),

                    /// Title
                    Expanded(
                      child: Text(
                        "Professional Dashboard",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.rf(14),
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
                        padding: EdgeInsets.only(top: context.rh(20)),
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
                          SizedBox(height: context.rh(10)),
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
                          SizedBox(height: context.rh(10)),
                          InsightListTile(
                            title: "Top Performing Reel",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PerformanceScreen(),
                              ),
                            ),
                          ),
                          SizedBox(height: context.rh(10)),
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
