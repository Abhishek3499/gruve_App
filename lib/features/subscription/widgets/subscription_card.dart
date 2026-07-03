import 'package:flutter/material.dart';
import 'slanted_card_clipper.dart';

class SubscriptionCard extends StatelessWidget {
  final String iconPath;
  final int coins;
  final String? centerImage;
  final String price;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  const SubscriptionCard({
    super.key,
    required this.iconPath,
    required this.coins,
    this.centerImage,
    required this.price,
    this.isSelected = false,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: CustomPaint(
          painter: SubscriptionCardPainter(isSelected: isSelected),
          child: ClipPath(
            clipper: SlantedCardClipper(),
            child: AnimatedOpacity(
              opacity: isLocked
                  ? 0.4
                  : isSelected
                  ? 1.0
                  : 0.6,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// Left side
                        Row(
                          children: [
                            Image.asset(iconPath, height: 32),
                            const SizedBox(width: 15),
                            Text(
                              '$coins',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
 
                        /// Right side
                        Text(
                          price,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
 
                  /// Center image
                  if (centerImage != null)
                    Image.asset(centerImage!, height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SubscriptionCardPainter extends CustomPainter {
  final bool isSelected;
  final double slantOffset;
  final double radius;
  final double obtuseRadius;

  SubscriptionCardPainter({
    required this.isSelected,
    this.slantOffset = 25.0,
    this.radius = 12.0,
    this.obtuseRadius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final double activeSlant = (h < 90.0) ? (slantOffset * h / 90.0) : slantOffset;
    final double activeRadius = (h < 90.0) ? (radius * h / 90.0) : radius;
    final double activeObtuseRadius = (h < 90.0) ? (obtuseRadius * h / 90.0) : obtuseRadius;

    final path = Path();
    path.moveTo(activeRadius, 0);
    path.lineTo(w - activeRadius, 0);
    path.quadraticBezierTo(w, 0, w, activeRadius);
    path.lineTo(w, h - activeRadius);
    path.quadraticBezierTo(w, h, w - activeRadius, h);
    path.lineTo(activeSlant + activeObtuseRadius, h);
    path.quadraticBezierTo(
      activeSlant,
      h,
      activeSlant - (activeObtuseRadius * activeSlant) / h,
      h - activeObtuseRadius,
    );
    path.lineTo((activeRadius * activeSlant) / h, activeRadius);
    path.quadraticBezierTo(0, 0, activeRadius, 0);
    path.close();

    // 1. Draw Outer Shadow: box-shadow: 0px 10px 20px 0px #00000040;
    final shadowPaint = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawPath(path.shift(const Offset(0, 10)), shadowPaint);

    // 2. Draw Background Gradient
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isSelected
            ? [const Color(0xFF4A2563), const Color(0xFF2A1A3A)]
            : [const Color(0xFF3B1D52), const Color(0xFF1E122D)],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // 3. Draw Inset Shadow for selected state:
    // box-shadow: -2px -2px 25px 0px #72008DE5 inset;
    if (isSelected) {
      canvas.save();
      canvas.clipPath(path);
      
      final insetPaint = Paint()
        ..color = const Color(0xE572008D) // #72008DE5
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25.0 // Matches 25px blur
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.5);
      
      canvas.drawPath(path.shift(const Offset(-2, -2)), insetPaint);
      canvas.restore();
    }

    // 4. Draw Border
    if (isSelected) {
      final borderPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB86AD0), Color(0xFF72008D)],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
