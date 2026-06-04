import 'package:flutter/material.dart';
import 'dart:math' as math;

class TeaspoonVisualizer extends StatelessWidget {
  final double sugarGrams;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const TeaspoonVisualizer({
    super.key,
    required this.sugarGrams,
    this.size = 24.0,
    this.activeColor = const Color(0xFF009688), // Teal
    this.inactiveColor = const Color(0xFFE0E0E0), // Light Grey
  });

  @override
  Widget build(BuildContext context) {
    // 1 teaspoon = 4 grams of sugar
    final double totalSpoons = sugarGrams / 4.0;
    
    // We visualize up to the next whole number, or at least 1
    final int spoonCount = math.max(1, totalSpoons.ceil());
    
    // Cap at reasonable max to avoid overflow UI (e.g., 20 spoons)
    final int displayCount = math.min(spoonCount, 12); 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(displayCount, (index) {
            double valueForThisSpoon = totalSpoons - index;
            double fillPercentage = valueForThisSpoon.clamp(0.0, 1.0);
            
            return _SpoonIcon(
              percentage: fillPercentage,
              size: size,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            );
          }),
        ),
        if (spoonCount > 12)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '+ ${spoonCount - 12} sendok lagi...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

// Function to get a friendly fraction string
String _getFractionString(double value) {
  int whole = value.floor();
  double fraction = value - whole;
  String fractionStr = '';
  
  if (fraction >= 0.125 && fraction < 0.375) {
    fractionStr = '¼';
  } else if (fraction >= 0.375 && fraction < 0.625) {
    fractionStr = '½';
  } else if (fraction >= 0.625 && fraction < 0.875) {
    fractionStr = '¾';
  }

  if (whole > 0 && fractionStr.isNotEmpty) {
    return '$whole $fractionStr';
  } else if (whole > 0) {
    return '$whole';
  } else if (fractionStr.isNotEmpty) {
    return fractionStr;
  }
  return '${value.toStringAsFixed(1)}';
}

class _SpoonIcon extends StatelessWidget {
  final double percentage;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const _SpoonIcon({
    required this.percentage,
    required this.size,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size, 
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background (Empty Spoon)
          CustomPaint(
            size: Size(size, size),
            painter: _SpoonPainter(color: inactiveColor),
          ),
          
          // Foreground (Filled based on percentage) using ClipRect vertically
          ClipRect(
            clipper: _VerticalClipper(percentage),
            child: CustomPaint(
              size: Size(size, size),
              painter: _SpoonPainter(color: activeColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalClipper extends CustomClipper<Rect> {
  final double percentage;

  _VerticalClipper(this.percentage);

  @override
  Rect getClip(Size size) {
    // Fill from bottom to top
    final fillHeight = size.height * percentage;
    return Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight);
  }

  @override
  bool shouldReclip(_VerticalClipper oldClipper) {
    return oldClipper.percentage != percentage;
  }
}

class _SpoonPainter extends CustomPainter {
  final Color color;

  _SpoonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;
    
    // Bowl (bottom part)
    // A spoon bowl is roughly an ellipse, slightly wider near the bottom than the top.
    final bowlRect = Rect.fromLTWH(w * 0.25, h * 0.55, w * 0.5, h * 0.45);
    path.addOval(bowlRect);
    
    // Handle
    // Thinner near the bowl, slightly wider at the top tip.
    final handlePath = Path();
    handlePath.moveTo(w * 0.45, h * 0.6); // bottom left (intersects bowl)
    handlePath.lineTo(w * 0.55, h * 0.6); // bottom right 
    handlePath.lineTo(w * 0.6, h * 0.05);  // top right (wider)
    
    // Top rounded part of handle
    handlePath.arcToPoint(
      Offset(w * 0.4, h * 0.05),
      radius: Radius.circular(w * 0.1),
      clockwise: false,
    );
    
    handlePath.lineTo(w * 0.45, h * 0.6); // back down
    
    path.addPath(handlePath, Offset.zero);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpoonPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
