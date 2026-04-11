import 'package:flutter/material.dart';
import '../../../../widgets/climb_skeleton.dart';


class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting & Avatar Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ClimbSkeleton(height: 14, width: 120),
                    const SizedBox(height: 8),
                    const ClimbSkeleton(height: 28, width: 180),
                  ],
                ),
                const ClimbSkeleton.circle(size: 44),
              ],
            ),
            const SizedBox(height: 20),

            // XP Progress Card Skeleton
            const ClimbSkeleton(height: 160, width: double.infinity, borderRadius: 24),
            const SizedBox(height: 16),

            // Daily Streak Skeleton
            const ClimbSkeleton(height: 80, width: double.infinity, borderRadius: 20),
            const SizedBox(height: 16),

            // Quick Stats Skeleton
            Row(
              children: [
                Expanded(child: const ClimbSkeleton(height: 90, borderRadius: 16)),
                const SizedBox(width: 12),
                Expanded(child: const ClimbSkeleton(height: 90, borderRadius: 16)),
                const SizedBox(width: 12),
                Expanded(child: const ClimbSkeleton(height: 90, borderRadius: 16)),
              ],
            ),
            const SizedBox(height: 24),

            // Today Tasks Title
            const ClimbSkeleton(height: 20, width: 140),
            const SizedBox(height: 16),

            // Task List Skeletons
            for (int i = 0; i < 3; i++) ...[
              const ClimbSkeleton(height: 70, width: double.infinity, borderRadius: 16),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
