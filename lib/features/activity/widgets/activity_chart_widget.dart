import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/activity_controller.dart';

class ActivityChartWidget extends StatelessWidget {
  final ActivityController controller;
  final FilterType filterType;

  const ActivityChartWidget({
    super.key,
    required this.controller,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    final data = controller.getDataFor(filterType);
    if (data.isEmpty) return const Center(child: Text("No Data"));

    // Peak calculation
    final peakHours = data.map((d) => d.hours).reduce((a, b) => a > b ? a : b);
    final peakIndex = data.indexWhere((d) => d.hours == peakHours);

    final spots = data
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.hours))
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D263B), // SS ka dark purple background
        borderRadius: BorderRadius.circular(16),
      ),
      height: 300,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: 10,

          // 1. Grid Styling (Dashed horizontal lines)
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.15),
                strokeWidth: 1.5,
                dashArray: [4, 4],
              );
            },
          ),

          // 2. Titles & Labels
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                reservedSize: 35,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 10,
                      child: Text(
                        data[index].day,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),

          borderData: FlBorderData(show: false),

          // 3. Line & Area Gradient
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: const Color(0xFF00CED1), // SS Teal Color
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (index == peakIndex) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.white,
                      strokeWidth: 4,
                      strokeColor: const Color(
                        0xFFF7941D,
                      ), // Orange Peak Border
                    );
                  }
                  return FlDotCirclePainter(radius: 0);
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00CED1).withOpacity(0.2),
                    const Color(0xFF00CED1).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],

          // 4. Vertical Peak Line
          extraLinesData: ExtraLinesData(
            verticalLines: [
              VerticalLine(
                x: peakIndex.toDouble(),
                color: const Color(0xFFF7941D),
                strokeWidth: 2,
              ),
            ],
          ),

          // 5. Tooltip Styling
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.white,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    data[spot.x.toInt()].time,
                    const TextStyle(
                      color: Color(0xFF2D263B),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
