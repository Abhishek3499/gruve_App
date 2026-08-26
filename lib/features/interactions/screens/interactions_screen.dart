import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/interactions_controller.dart';
import '../models/interactions_model.dart';
import '../widgets/interactions_header.dart';
import '../widgets/interactions_count_section.dart';
import '../widgets/interactions_donut_chart.dart';
import '../widgets/interactions_followers_stats.dart';
import '../widgets/interactions_account_reached.dart';
import '../widgets/interactions_content_tabs.dart';
import '../widgets/interactions_progress_bar.dart';
import '../widgets/interactions_footer.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Interactions screen with modular architecture
class InteractionsScreen extends StatefulWidget {
  const InteractionsScreen({super.key});

  @override
  State<InteractionsScreen> createState() => _InteractionsScreenState();
}

class _InteractionsScreenState extends State<InteractionsScreen> {
  late final InteractionsController _controller;

  @override
  void initState() {
    super.initState();
    AppLogger.d("[InteractionsScreen] Screen initialized");
    _controller = InteractionsController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2B0033), Color(0xFF14001A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              const InteractionsHeader(),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: context.rh(15)),

                      // COUNT ABOVE DONUT
                      const InteractionsCountSection(),

                      SizedBox(height: context.rh(40)),

                      // DONUT + LEFT/RIGHT STATS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: InteractionsFollowersStats(isLeft: true),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: context.rw(20)),
                            child: const InteractionsDonutChart(),
                          ),

                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InteractionsFollowersStats(isLeft: false),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.rh(40)),

                      // ACCOUNT REACHED
                      const InteractionsAccountReached(),

                      SizedBox(height: context.rh(26)),

                      // By Content Type Heading
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.rw(16)),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'By content type',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.rf(14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.rh(16)),

                      // CONTENT TABS
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, child) {
                          return InteractionsContentTabs(
                            controller: _controller,
                          );
                        },
                      ),

                      SizedBox(height: context.rh(32)),

                      // PROGRESS BARS
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.rw(16)),
                        child: ListenableBuilder(
                          listenable: _controller,
                          builder: (context, child) {
                            return Column(
                              children: InteractionsModel.data.contentTypes.map(
                                (contentType) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: context.rh(32)),
                                    child: InteractionsProgressBar(
                                      label: contentType.label,
                                      percentage: contentType.percentage,
                                    ),
                                  );
                                },
                              ).toList(),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: context.rh(20)),

                      const InteractionsFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
