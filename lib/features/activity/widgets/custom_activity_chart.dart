import 'package:flutter/material.dart';
import '../controllers/activity_controller.dart';
import '../models/activity_model.dart';

class CustomActivityChart extends StatefulWidget {
  final ActivityController controller;
  final FilterType filterType;

  const CustomActivityChart({
    super.key,
    required this.controller,
    required this.filterType,
  });

  @override
  State<CustomActivityChart> createState() => _CustomActivityChartState();
}

class _CustomActivityChartState extends State<CustomActivityChart>
    with TickerProviderStateMixin {
  int? _activeIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _activeIndex = 4;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    setState(() {
      _activeIndex = index;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.getDataFor(widget.filterType);
    if (data.isEmpty) return const SizedBox();

    return SizedBox(
      height: 215,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: ChartPainter(
                data: data,
                activeIndex: _activeIndex,
                animation: _animation,
              ),
            ),
          ),
          // Touch detection layer
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localOffset = box.globalToLocal(details.globalPosition);
                const padding = EdgeInsets.fromLTRB(31, 17, 0, 30);
                final chartWidth =
                    box.size.width - padding.left - padding.right;
                final sectionWidth = chartWidth / (data.length - 1);
                final tappedIndex =
                    ((localOffset.dx - padding.left) / sectionWidth).round();

                if (tappedIndex >= 0 && tappedIndex < data.length) {
                  _handleTap(tappedIndex);
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<ActivityData> data;
  final int? activeIndex;
  final Animation<double> animation;

  ChartPainter({
    required this.data,
    required this.activeIndex,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    const padding = EdgeInsets.fromLTRB(31, 17, 0, 30);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;
    final sectionWidth = chartWidth / (data.length - 1);

    _drawGridLines(canvas, padding, chartWidth, chartHeight);
    _drawAxisLabels(canvas, padding, chartHeight, sectionWidth);
    _drawLineShade(canvas, padding, chartWidth, chartHeight, sectionWidth);
    _drawLine(canvas, padding, chartHeight, sectionWidth);

    if (activeIndex != null) {
      _drawActiveState(canvas, padding, chartHeight, sectionWidth);
    }
  }

  double _chartY(EdgeInsets padding, double chartHeight, double hours) {
    final displayHours = hours > 8 ? 8 : hours;
    return padding.top + chartHeight - (displayHours / 10) * chartHeight;
  }

  void _drawGridLines(
    Canvas canvas,
    EdgeInsets padding,
    double chartWidth,
    double chartHeight,
  ) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 5; i++) {
      final y = padding.top + (chartHeight / 5) * i;
      final startX = padding.left;
      final endX = padding.left + chartWidth;

      const dashWidth = 1.2;
      const dashSpace = 4.0;
      double currentX = startX;

      while (currentX < endX) {
        final nextX = (currentX + dashWidth).clamp(startX, endX);
        canvas.drawLine(Offset(currentX, y), Offset(nextX, y), gridPaint);
        currentX = nextX + dashSpace;
      }
    }
  }

  void _drawAxisLabels(
    Canvas canvas,
    EdgeInsets padding,
    double chartHeight,
    double sectionWidth,
  ) {
    const labelStyle = TextStyle(
      color: Color(0xFFA8A1B3),
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    );

    const yLabels = ['0', '2', '4', '6', '8', '10'];
    for (int i = 0; i < yLabels.length; i++) {
      final y = padding.top + chartHeight - (chartHeight / 5) * i;
      final textPainter = TextPainter(
        text: TextSpan(text: yLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(padding.left - 30, y - textPainter.height / 2),
      );
    }

    for (int i = 0; i < data.length; i++) {
      final x = padding.left + sectionWidth * i;
      final textPainter = TextPainter(
        text: TextSpan(text: data[i].day, style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, padding.top + chartHeight + 13),
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    EdgeInsets padding,
    double chartHeight,
    double sectionWidth,
  ) {
    final linePaint = Paint()
      ..color = const Color(0xFF18D8F5)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = padding.left + sectionWidth * i;
      final y = _chartY(padding, chartHeight, data[i].hours);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = padding.left + sectionWidth * (i - 1);
        final prevY = _chartY(padding, chartHeight, data[i - 1].hours);
        final controlX1 = prevX + sectionWidth * 0.38;
        final controlY1 = prevY;
        final controlX2 = x - sectionWidth * 0.38;
        final controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  void _drawLineShade(
    Canvas canvas,
    EdgeInsets padding,
    double chartWidth,
    double chartHeight,
    double sectionWidth,
  ) {
    final path = Path()..moveTo(padding.left, padding.top + chartHeight);

    for (int i = 0; i < data.length; i++) {
      final x = padding.left + sectionWidth * i;
      final y = _chartY(padding, chartHeight, data[i].hours);

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        final prevX = padding.left + sectionWidth * (i - 1);
        final prevY = _chartY(padding, chartHeight, data[i - 1].hours);
        final controlX1 = prevX + sectionWidth * 0.38;
        final controlY1 = prevY;
        final controlX2 = x - sectionWidth * 0.38;
        final controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    path
      ..lineTo(padding.left + chartWidth, padding.top + chartHeight)
      ..close();

    final paint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF18D8F5).withValues(alpha: 0.16),
              const Color(0xFF18D8F5).withValues(alpha: 0.04),
              const Color(0xFF18D8F5).withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromLTWH(padding.left, padding.top, chartWidth, chartHeight),
          );

    canvas.drawPath(path, paint);
  }

  void _drawActiveState(
    Canvas canvas,
    EdgeInsets padding,
    double chartHeight,
    double sectionWidth,
  ) {
    final x = padding.left + sectionWidth * activeIndex!;
    final y = _chartY(padding, chartHeight, data[activeIndex!].hours);

    final verticalLinePaint = Paint()
      ..color = const Color(0xFFFF981F)
      ..strokeWidth = 1.4;

    canvas.drawLine(
      Offset(x, y),
      Offset(x, padding.top + chartHeight),
      verticalLinePaint,
    );

    final outerPaint = Paint()
      ..color = const Color(0xFFFF981F)
      ..style = PaintingStyle.fill;
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), 6.8 * animation.value, outerPaint);
    canvas.drawCircle(Offset(x, y), 4.1 * animation.value, innerPaint);

    _drawTooltip(canvas, x, y, data[activeIndex!].time);
  }

  void _drawTooltip(Canvas canvas, double x, double y, String time) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: time,
        style: const TextStyle(
          color: Color(0xFF313052),
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final tooltipWidth = textPainter.width + 18;
    const tooltipHeight = 29.0;
    final tooltipX = x - tooltipWidth / 2;
    final tooltipY = y - tooltipHeight - 16;

    final tooltipPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
      const Radius.circular(5),
    );

    canvas.drawRRect(rrect, tooltipPaint);

    textPainter.paint(
      canvas,
      Offset(tooltipX + 8, tooltipY + (tooltipHeight - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
