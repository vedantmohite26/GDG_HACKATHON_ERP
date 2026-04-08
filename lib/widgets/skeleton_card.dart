import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkeletonCard extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  const SkeletonCard({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 16,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color:
                Theme.of(context).cardTheme.color?.withValues(alpha: 0.05) ??
                Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color:
              Theme.of(context).cardTheme.color?.withValues(alpha: 0.1) ??
              Colors.white.withValues(alpha: 0.1),
          angle: 0.8, // Diagonal shimmer
        );
  }
}
