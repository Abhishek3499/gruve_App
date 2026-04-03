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
    // Set Thursday (index 3) as default active
    _activeIndex = 3;
    
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

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A2E), // Deep purple-dark background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B46C1).withValues(alpha: 0.3), // Purple glow
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      height: 300,
      child: Stack(
        children: [
          // Custom Paint Chart
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
                final Offset localOffset = box.globalToLocal(details.globalPosition);
                final chartWidth = box.size.width - 50; // Account for padding
                final sectionWidth = chartWidth / data.length;
                final tappedIndex = (localOffset.dx - 35) ~/ sectionWidth;
                
                if (tappedIndex >= 0 && tappedIndex < data.length) {
                  _handleTap(tappedIndex);
                }
              },
              child: Container(
                color: Colors.transparent,
              ),
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
    final padding = EdgeInsets.fromLTRB(35, 20, 20, 40);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;
    final sectionWidth = chartWidth / (data.length - 1);

    // Draw grid lines
    _drawGridLines(canvas, padding, chartWidth, chartHeight);

    // Draw axes labels
    _drawAxisLabels(canvas, padding, chartWidth, chartHeight, sectionWidth);

    // Draw gradient fill under line
    _drawGradientFill(canvas, padding, chartWidth, chartHeight, sectionWidth);

    // Draw the line
    _drawLine(canvas, padding, chartWidth, chartHeight, sectionWidth);

    // Draw data points
    _drawDataPoints(canvas, padding, chartWidth, chartHeight, sectionWidth);

    // Draw active state if any
    if (activeIndex != null) {
      _drawActiveState(canvas, padding, chartWidth, chartHeight, sectionWidth);
    }
  }

  void _drawGridLines(Canvas canvas, EdgeInsets padding, double chartWidth, double chartHeight) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.5;

    for (int i = 0; i <= 5; i++) {
      final y = padding.top + (chartHeight / 5) * i;
      final startX = padding.left;
      final endX = padding.left + chartWidth;

      // Draw dashed line
      final dashWidth = 4.0;
      final dashSpace = 4.0;
      double currentX = startX;

      while (currentX < endX) {
        final nextX = (currentX + dashWidth).clamp(startX, endX);
        canvas.drawLine(
          Offset(currentX, y),
          Offset(nextX, y),
          gridPaint,
        );
        currentX = nextX + dashSpace;
      }
    }
  }

  void _drawAxisLabels(Canvas canvas, EdgeInsets padding, double chartWidth, double chartHeight, double sectionWidth) {
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 13,
    );

    // Y-axis labels
    final yLabels = ['0', '2', '4', '6', '8', '10'];
    for (int i = 0; i < yLabels.length; i++) {
      final y = padding.top + chartHeight - (chartHeight / 5) * i;
      final textPainter = TextPainter(
        text: TextSpan(text: yLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(padding.left - 25, y - textPainter.height / 2),
      );
    }

    // X-axis labels
    for (int i = 0; i < data.length; i++) {
      final x = padding.left + sectionWidth * i;
      final textPainter = TextPainter(
        text: TextSpan(text: data[i].day, style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, padding.top + chartHeight + 10),
      );
    }
  }

  void _drawGradientFill(Canvas canvas, EdgeInsets padding, double chartWidth, double chartHeight, double sectionWidth) {
    final path = Path();
    
    // Start from bottom left
    path.moveTo(padding.left, padding.top + chartHeight);
    
    // Add points for the line
    for (int i = 0; i < data.length; i++) {
      final x = padding.left + sectionWidth * i;
      final y = padding.top + chartHeight - (data[i].hours / 10) * chartHeight;
      
      if (i == 0) {
        path.lineTo(x, y);
      } else {
        // Create smooth curve using cubic bezier
        final prevX = padding.left + sectionWidth * (i - 1);
        final prevY = padding.top + chartHeight - (data[i - 1].hours / 10) * chartHeight;
        final controlX1 = prevX + sectionWidth * 0.3;
        final controlY1 = prevY;
        final controlX2 = x - sectionWidth * 0.3;
        final controlY2 = y;
        
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }
    
    // Close the path at bottom right
    path.lineTo(padding.left + chartWidth, padding.top + chartHeight);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF00BFA5).withValues(alpha: 0.2),
        const Color(0xFF00BFA5).withValues(alpha: 0.0),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(padding.left, padding.top, chartWidth, chartHeight),
      );

    canvas.drawPath(path, paint);
  }

  void _drawLine(Canvas canvas, EdgeInsets padding, double chartWidth, double chartHeight, double sectionWidth) {
    final linePaint = Paint()
      ..color = const Color(0xFF00BFA5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2); // Glow effect

    final path = Path();
    
    for (int i = 0; i < data.length; i++) {
      final x = padding.left + sectionWidth * i;
      final y = padding.top + chartHeight - (data[i].hours / 10) * chartHeight;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Create smooth curve using cubic bezier
        final prevX = padding.left + sectionWidth * (i - 1);
        final prevY = padding.top + chartHeight - (data[i - 1].hours / 10) * chartHeight;
        final controlX1 = prevX + sectionWidth * 0.3;
        final controlY1 = prevY;
        final controlX2 = x - sectionWidth * 0.3;
        final controlY2 = y;
        
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  void _drawDataPoints(Canvas canvas, EdgeInsets padding, double chartWidth, double chartHeight, double sectionWidth) {
    for (int i = 0; i < data.length; i++) {
      final x = padding.left + sectionWidth * i;
      final y = padding.top + chartHeight - (data[i].hours / 10) * chartHeight;
      
      // Draw small dot for each point
      final dotPaint = Paint()
        ..color = const Color(0xFF00BFA5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  void _drawActiveState(Canvas canvas, EdgeInsets padding, double chartWidth, double chartHeight, double sectionWidth) {
    final x = padding.left + sectionWidth * activeIndex!;
    final y = padding.top + chartHeight - (data[activeIndex!].hours / 10) * chartHeight;

    // Draw vertical line
    final verticalLinePaint = Paint()
      ..color = const Color(0xFFFF9800) // Orange/amber color
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(x, y),
      Offset(x, padding.top + chartHeight),
      verticalLinePaint,
    );

    // Draw glowing dot
    final glowPaint = Paint()
      ..color = const Color(0xFF00BFA5)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * animation.value);

    canvas.drawCircle(Offset(x, y), 8 * animation.value, glowPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF00BFA5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), 6 * animation.value, dotPaint);

    // Draw tooltip
    _drawTooltip(canvas, x, y, data[activeIndex!].time);
  }

  void _drawTooltip(Canvas canvas, double x, double y, String time) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: time,
        style: const TextStyle(
          color: Color(0xFF1E1A2E),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final tooltipWidth = textPainter.width + 16;
    final tooltipHeight = 28;
    final tooltipX = x - tooltipWidth / 2;
    final tooltipY = y - tooltipHeight - 10;

    // Draw tooltip background
    final tooltipPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight.toDouble()),
      const Radius.circular(14),
    );

    canvas.drawRRect(rrect, tooltipPaint);

    // Draw text
    textPainter.paint(
      canvas,
      Offset(tooltipX + 8, tooltipY + (tooltipHeight - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
