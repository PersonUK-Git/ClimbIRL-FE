import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ClimbSkeleton extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;
  final BoxShape shape;

  const ClimbSkeleton({
    super.key,
    this.height,
    this.width,
    this.borderRadius = 6,
    this.shape = BoxShape.rectangle,
  });

  const ClimbSkeleton.circle({
    super.key,
    required double size,
  })  : height = size,
        width = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surface,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(borderRadius)
              : null,
        ),
      ),
    );
  }
}
