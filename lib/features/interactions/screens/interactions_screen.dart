import 'package:flutter/material.dart';
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
    debugPrint("[InteractionsScreen] Screen initialized");
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
                      const SizedBox(height: 15),

                      // COUNT ABOVE DONUT
                      const InteractionsCountSection(),

                      const SizedBox(height: 40),

                      // DONUT + LEFT/RIGHT STATS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: InteractionsFollowersStats(isLeft: true),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: InteractionsDonutChart(),
                          ),

                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InteractionsFollowersStats(isLeft: false),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ACCOUNT REACHED
                      const InteractionsAccountReached(),

                      const SizedBox(height: 26),

                      // By Content Type Heading
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'By content type',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // CONTENT TABS
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, child) {
                          return InteractionsContentTabs(
                            controller: _controller,
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // PROGRESS BARS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListenableBuilder(
                          listenable: _controller,
                          builder: (context, child) {
                            return Column(
                              children: InteractionsModel.data.contentTypes.map(
                                (contentType) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 32),
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

                      const SizedBox(height: 20),

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
