import 'package:flutter/material.dart';

/// Animated XP progress bar with gradient fill.
class XPBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final BorderRadius? borderRadius;

  const XPBar({
    super.key,
    required this.progress,
    this.height = 12,
    this.backgroundColor,
    this.gradientColors,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final br = borderRadius ?? BorderRadius.circular(height / 2);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: br,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors ??
                        [
                          cs.primary,
                          cs.primary.withValues(alpha: 0.7),
                        ],
                  ),
                  borderRadius: br,
                  boxShadow: [
                    BoxShadow(
                      color: (gradientColors?.first ?? cs.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              // Shimmer highlight
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                height: height / 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                  borderRadius: br,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
