import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/views_model.dart';

/// Animated donut chart widget
class ViewsDonutChart extends StatefulWidget {
  const ViewsDonutChart({super.key});

  @override
  State<ViewsDonutChart> createState() => _ViewsDonutChartState();
}

class _ViewsDonutChartState extends State<ViewsDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _DonutPainter(
              followersPercentage:
                  ViewsModel.data.followersPercentage * _animation.value,
              nonFollowersPercentage:
                  ViewsModel.data.nonFollowersPercentage * _animation.value,
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for donut chart
class _DonutPainter extends CustomPainter {
  final double followersPercentage;
  final double nonFollowersPercentage;

  _DonutPainter({
    required this.followersPercentage,
    required this.nonFollowersPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = AppColors.white.withAlpha(26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Followers arc
    final followersPaint = Paint()
      ..color = const Color(0xFF72008D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.butt;

    final followersAngle = (followersPercentage / 100) * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      followersAngle,
      false,
      followersPaint,
    );

    // Non-followers arc
    final nonFollowersPaint = Paint()
      ..color = const Color(0xFFFF3AFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.butt;

    final nonFollowersAngle = (nonFollowersPercentage / 100) * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708 + followersAngle,
      nonFollowersAngle,
      false,
      nonFollowersPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return followersPercentage != oldDelegate.followersPercentage ||
        nonFollowersPercentage != oldDelegate.nonFollowersPercentage;
  }
}
