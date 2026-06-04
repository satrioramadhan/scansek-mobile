import 'package:flutter/material.dart';
import 'dart:math' as math;

class RealisticWaterGlass extends StatelessWidget {
  final double percentage; // 0.0 to 1.0
  final double width;
  final double height;

  const RealisticWaterGlass({
    super.key,
    required this.percentage,
    this.width = 60,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp percentage
    final fillLevel = percentage.clamp(0.0, 1.0);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GlassPainter(fillLevel: fillLevel),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  final double fillLevel;

  _GlassPainter({required this.fillLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Glass Shape Parameters
    final topWidth = size.width;
    final bottomWidth = size.width * 0.75;
    final height = size.height;
    
    final xCenter = size.width / 2;
    
    // 1. Draw Water
    if (fillLevel > 0) {
      final waterHeight = height * fillLevel;
      final waterTopY = height - waterHeight;
      
      // Calculate width at water level (linear interpolation)
      final waterTopWidth = bottomWidth + (topWidth - bottomWidth) * fillLevel;
      
      final waterPath = Path();
      waterPath.moveTo(xCenter - waterTopWidth / 2, waterTopY);
      waterPath.lineTo(xCenter + waterTopWidth / 2, waterTopY);
      waterPath.lineTo(xCenter + bottomWidth / 2, height);
      waterPath.lineTo(xCenter - bottomWidth / 2, height);
      waterPath.close();

      // Graident for water
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF90CAF9), // Blue 200
          const Color(0xFF64B5F6), // Blue 300
        ],
      );
      
      paint.shader = gradient.createShader(Rect.fromLTWH(0, waterTopY, size.width, waterHeight));
      paint.style = PaintingStyle.fill;
      canvas.drawPath(waterPath, paint);
      paint.shader = null;

      // Water Surface (Ellipse)
      paint.color = const Color(0xFF64B5F6); // Lighter Blue for surface
      paint.style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(xCenter, waterTopY),
          width: waterTopWidth,
          height: waterTopWidth * 0.15, // Flattened ellipse
        ),
        paint,
      );
    }

    // 2. Draw Glass Container (Outline)
    final glassPath = Path();
    glassPath.moveTo(xCenter - topWidth / 2, 0);
    glassPath.lineTo(xCenter + topWidth / 2, 0);
    glassPath.lineTo(xCenter + bottomWidth / 2, height);
    glassPath.lineTo(xCenter - bottomWidth / 2, height);
    glassPath.close();

    // Glass Wall style
    paint.color = Colors.white.withOpacity(0.3); // Semi-transparent glass
    paint.style = PaintingStyle.fill;
    canvas.drawPath(glassPath, paint);

    paint.color = const Color(0xFF90CAF9); // Light Blue Border
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawPath(glassPath, paint);

    // 3. Glass Rim (Top Ellipse)
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = const Color(0xFF90CAF9);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(xCenter, 0),
        width: topWidth,
        height: topWidth * 0.15,
      ),
      paint,
    );
    
    // 4. White Reflection/Shine (Optional for realism)
    final shinePath = Path();
    shinePath.moveTo(xCenter + bottomWidth/2 - 5, height - 5);
    shinePath.lineTo(xCenter + topWidth/2 - 5, 10);
    paint.color = Colors.white.withOpacity(0.4);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    paint.strokeCap = StrokeCap.round;
    // content of drawing shine... actually simple vertical line is enough
    canvas.drawLine(
      Offset(xCenter + topWidth/2 - 8, 10),
      Offset(xCenter + bottomWidth/2 - 6, height - 10),
      paint
    );
  }

  @override
  bool shouldRepaint(covariant _GlassPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel;
  }
}
