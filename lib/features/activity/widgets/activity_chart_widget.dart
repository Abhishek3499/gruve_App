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
    final maxY = data.map((d) => d.hours).reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,

        // GRID
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,

          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withAlpha(77),
              strokeWidth: 1,
              dashArray: [4, 4],
            );
          },

          checkToShowHorizontalLine: (value) {
            // 🔥 FORCE include 0
            if (value == 0) return true;

            // normal lines (0–10)
            return value >= 0 && value <= 10;
          },
        ),

        // TITLES
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value > 10) return const SizedBox(); // 🔥 extra remove
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[index].day,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),

        borderData: FlBorderData(show: false),

        // LINE
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((entry) => FlSpot(entry.key.toDouble(), entry.value.hours))
                .toList(),
            isCurved: true,
            color: const Color(0xFF00E5FF),
            barWidth: 1,
            isStrokeCapRound: true,

            // DOTS
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final peakIndex = data.indexWhere(
                  (d) =>
                      d.hours ==
                      data.map((d) => d.hours).reduce((a, b) => a > b ? a : b),
                );
                if (index == peakIndex) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xFFFFA84A),
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                );
              },
            ),

            // AREA GRADIENT
            belowBarData: BarAreaData(
              show: true,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.36, 0.99],
                colors: [Color(0xFF0AE1EF), Color(0x0004BFDA)],
              ),
            ),
          ),
        ],

        // TOOLTIP
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white,
            tooltipRoundedRadius: 12,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.toInt();
                return LineTooltipItem(
                  data[index].time,
                  const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),

        // VERTICAL LINE at peak
        extraLinesData: ExtraLinesData(
          verticalLines: [
            VerticalLine(
              x: data
                  .indexWhere(
                    (d) =>
                        d.hours ==
                        data
                            .map((d) => d.hours)
                            .reduce((a, b) => a > b ? a : b),
                  )
                  .toDouble(),
              color: const Color(0xFFFFA84A),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
