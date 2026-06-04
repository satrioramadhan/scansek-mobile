import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

/// Shimmer loading effect untuk list items
class ShimmerLoader extends StatelessWidget {
  final Widget child;

  const ShimmerLoader({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: child,
    );
  }
}

/// Shimmer untuk card loading
class ShimmerCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;

  const ShimmerCard({
    super.key,
    this.height = 120,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

/// Shimmer untuk list item
class ShimmerListTile extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const ShimmerListTile({
    super.key,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 200,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 150,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loader untuk tracker card di dashboard
class ShimmerTrackerCard extends StatelessWidget {
  const ShimmerTrackerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: ShimmerCard(height: 160),
    );
  }
}
