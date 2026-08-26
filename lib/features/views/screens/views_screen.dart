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
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

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
    AppLogger.d("[ViewsScreen] Screen initialized");
    _controller = ViewsController();
  }

  @override
  void dispose() {
    AppLogger.d("[ViewsScreen] Screen disposed");
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
                      SizedBox(height: context.rh(15)),

                      /// COUNT ABOVE DONUT
                      const ViewsCountSection(),

                      SizedBox(height: context.rh(40)),

                      /// DONUT + LEFT/RIGHT STATS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ViewsFollowersStats(isLeft: true),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: context.rw(20)),
                            child: const ViewsDonutChart(),
                          ),

                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ViewsFollowersStats(isLeft: false),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.rh(35)),

                      /// ACCOUNT REACHED
                      const ViewsAccountReached(),

                      SizedBox(height: context.rh(26)),

                      /// By Content Type Heading
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

                      /// CONTENT TABS
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, child) {
                          return ViewsContentTabs(controller: _controller);
                        },
                      ),

                      SizedBox(height: context.rh(32)),

                      /// PROGRESS BARS
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.rw(16)),
                        child: ListenableBuilder(
                          listenable: _controller,
                          builder: (context, child) {
                            return Column(
                              children: ViewsModel.data.contentTypes.map((
                                contentType,
                              ) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: context.rh(32)),
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

                      SizedBox(height: context.rh(20)),

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
