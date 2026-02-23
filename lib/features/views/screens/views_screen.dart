import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/views_controller.dart';
import '../models/views_model.dart';
import '../widgets/views_header.dart';
import '../widgets/views_count_section.dart';
import '../widgets/views_donut_chart.dart';
import '../widgets/views_followers_stats.dart';
import '../widgets/views_account_reached.dart';
import '../widgets/views_content_tabs.dart';
import '../widgets/views_progress_bar.dart';
import '../widgets/views_footer.dart';

class ViewsScreen extends StatefulWidget {
  const ViewsScreen({super.key});

  @override
  State<ViewsScreen> createState() => _ViewsScreenState();
}

class _ViewsScreenState extends State<ViewsScreen> {
  late final ViewsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ViewsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              const ViewsHeader(),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      /// COUNT ABOVE DONUT
                      const ViewsCountSection(),

                      const SizedBox(height: 24),

                      /// DONUT + LEFT/RIGHT STATS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ViewsFollowersStats(isLeft: true),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: ViewsDonutChart(),
                          ),

                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ViewsFollowersStats(isLeft: false),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      /// ACCOUNT REACHED
                      const ViewsAccountReached(),

                      const SizedBox(height: 26),

                      /// By Content Type Heading
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

                      /// CONTENT TABS
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, child) {
                          return ViewsContentTabs(controller: _controller);
                        },
                      ),

                      const SizedBox(height: 32),

                      /// PROGRESS BARS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListenableBuilder(
                          listenable: _controller,
                          builder: (context, child) {
                            return Column(
                              children: ViewsModel.data.contentTypes.map((
                                contentType,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: ViewsProgressBar(
                                    label: contentType.label,
                                    percentage: contentType.percentage,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      const ViewsFooter(),
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
