import 'dart:math';
import 'package:flutter/material.dart';
import 'package:scansek/app/core/theme/app_colors.dart';

/// Animated form background for auth screens.
/// Features randomly distributed blobs with entrance animation + continuous float.
/// Each page uses a different [seed] for unique blob placement.
class AnimatedAuthFormBackground extends StatefulWidget {
  final Widget child;
  final int seed;

  const AnimatedAuthFormBackground({
    super.key,
    required this.child,
    required this.seed,
  });

  @override
  State<AnimatedAuthFormBackground> createState() =>
      _AnimatedAuthFormBackgroundState();
}

class _AnimatedAuthFormBackgroundState extends State<AnimatedAuthFormBackground>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _floatController;
  late Animation<double> _entranceAnimation;
  late List<_BlobData> _blobs;

  @override
  void initState() {
    super.initState();

    // Entrance animation: fade-in + slide
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    // Continuous gentle floating
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _generateBlobs();
    _entranceController.forward();
  }

  void _generateBlobs() {
    final random = Random(widget.seed);

    // Pastel color palette
    final colors = [
      AppColors.chartOrange.withOpacity(0.08),
      AppColors.chartWater.withOpacity(0.12),
      AppColors.primary.withOpacity(0.08),
      AppColors.chartCaloriesConsumed.withOpacity(0.1),
      AppColors.chartActivityJogging.withOpacity(0.1),
    ];

    // Use QUADRANT-based distribution so blobs never cluster together
    // Divide the area into 4 quadrants and place 1 blob per quadrant
    // [0] top-left, [1] top-right, [2] bottom-left, [3] bottom-right
    _blobs = List.generate(4, (index) {
      final qx = index % 2; // 0 = left half, 1 = right half
      final qy = index ~/ 2; // 0 = top half, 1 = bottom half

      // Position within quadrant (with padding from edges)
      double endX = (qx * 0.45) + 0.08 + (random.nextDouble() * 0.35);
      double endY = (qy * 0.45) + 0.08 + (random.nextDouble() * 0.35);

      // Start slightly offset for entrance animation
      double startX = endX + (random.nextDouble() - 0.5) * 0.3;
      double startY = endY + (random.nextDouble() - 0.5) * 0.3;

      double size = 50.0 + (random.nextDouble() * 90.0);
      Color color = colors[random.nextInt(colors.length)];

      // Each blob gets a unique phase offset for floating
      double phase = random.nextDouble() * pi * 2;

      return _BlobData(
        startX: startX,
        startY: startY,
        endX: endX,
        endY: endY,
        size: size,
        color: color,
        phase: phase,
      );
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -10),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceAnimation, _floatController]),
          builder: (context, _) {
            final entrance = _entranceAnimation.value;
            final floatT = _floatController.value;

            return Stack(
              children: [
                // Animated Background Blobs
                ..._blobs.map((blob) {
                  // Entrance: interpolate from start to end position
                  final baseX =
                      blob.startX + (blob.endX - blob.startX) * entrance;
                  final baseY =
                      blob.startY + (blob.endY - blob.startY) * entrance;

                  // Continuous float: gentle sine wave offset unique per blob
                  final floatX = sin(floatT * pi * 2 + blob.phase) * 4;
                  final floatY = cos(floatT * pi * 2 + blob.phase * 1.3) * 3;

                  return Positioned(
                    left: baseX * screenWidth - (blob.size / 2) + floatX,
                    top: baseY * 500 - (blob.size / 2) + floatY,
                    child: Opacity(
                      opacity: entrance,
                      child: Container(
                        width: blob.size,
                        height: blob.size,
                        decoration: BoxDecoration(
                          color: blob.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),

                // Form Content
                widget.child,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BlobData {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  final Color color;
  final double phase;

  _BlobData({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.size,
    required this.color,
    required this.phase,
  });
}
