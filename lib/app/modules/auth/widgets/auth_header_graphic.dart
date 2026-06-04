import 'dart:math';
import 'package:flutter/material.dart';
import 'package:scansek/app/core/theme/app_colors.dart';

/// Animated header graphic for auth screens.
/// Features gentle continuously floating blobs + entrance fade-in.
class AuthHeaderGraphic extends StatefulWidget {
  final Widget child;
  final double height;
  final bool isSolid;

  const AuthHeaderGraphic({
    super.key,
    required this.child,
    this.height = 240,
    this.isSolid = false,
  });

  @override
  State<AuthHeaderGraphic> createState() => _AuthHeaderGraphicState();
}

class _AuthHeaderGraphicState extends State<AuthHeaderGraphic>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _entranceController;
  late Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();

    // Continuous gentle floating
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Entrance fade-in + scale
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSolid = widget.isSolid;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatController, _entranceAnimation]),
        builder: (context, child) {
          final t = _floatController.value;
          final entrance = _entranceAnimation.value;

          // Different phase offsets for each blob so they float independently
          final offset1 = sin(t * pi * 2) * 6;
          final offset2 = cos(t * pi * 2) * 5;
          final offset3 = sin(t * pi * 2 + pi / 3) * 4;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Giant Background Blob (circular)
              Positioned(
                top: -40 + offset1,
                child: Opacity(
                  opacity: entrance,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      color: isSolid
                          ? Colors.white.withOpacity(0.15)
                          : AppColors.chartWater.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Top Right Rounded Box
              Positioned(
                right: -20 + offset2,
                top: -20 + offset3,
                child: Opacity(
                  opacity: entrance,
                  child: Container(
                    width: 140,
                    height: 140,
                    transform: Matrix4.rotationZ(0.2),
                    decoration: BoxDecoration(
                      color: isSolid
                          ? Colors.white.withOpacity(0.18)
                          : AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
              ),

              // Bottom Left Rounded Box
              Positioned(
                left: -30 + offset3,
                bottom: 20 + offset1,
                child: Opacity(
                  opacity: entrance,
                  child: Container(
                    width: 100,
                    height: 100,
                    transform: Matrix4.rotationZ(-0.2),
                    decoration: BoxDecoration(
                      color: isSolid
                          ? Colors.white.withOpacity(0.16)
                          : AppColors.chartOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              // Decorative dot 1
              Positioned(
                top: 60 + offset2,
                left: 40 + offset3,
                child: Opacity(
                  opacity: entrance,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isSolid
                          ? Colors.white.withOpacity(0.25)
                          : AppColors.chartOrange.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Decorative dot 2
              Positioned(
                bottom: 40 + offset1,
                right: 40 + offset2,
                child: Opacity(
                  opacity: entrance,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSolid
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.chartWater.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Decorative dot 3
              Positioned(
                top: 20 + offset3,
                right: 80 + offset1,
                child: Opacity(
                  opacity: entrance,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isSolid
                          ? Colors.white.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Center Content (icon + title)
              Opacity(
                opacity: entrance,
                child: Transform.translate(
                  offset: Offset(0, (1 - entrance) * 20),
                  child: widget.child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
