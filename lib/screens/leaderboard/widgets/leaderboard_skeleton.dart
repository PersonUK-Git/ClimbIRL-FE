import 'package:flutter/material.dart';
import '../../../../widgets/climb_skeleton.dart';

class LeaderboardSkeleton extends StatelessWidget {
  const LeaderboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Podium Skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd
              Expanded(
                child: Column(
                  children: [
                    const ClimbSkeleton.circle(size: 48),
                    const SizedBox(height: 12),
                    const ClimbSkeleton(height: 12, width: 60),
                    const SizedBox(height: 8),
                    const ClimbSkeleton(height: 90, borderRadius: 12),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 1st
              Expanded(
                child: Column(
                  children: [
                    const ClimbSkeleton.circle(size: 60),
                    const SizedBox(height: 12),
                    const ClimbSkeleton(height: 14, width: 70),
                    const SizedBox(height: 8),
                    const ClimbSkeleton(height: 120, borderRadius: 12),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 3rd
              Expanded(
                child: Column(
                  children: [
                    const ClimbSkeleton.circle(size: 48),
                    const SizedBox(height: 12),
                    const ClimbSkeleton(height: 12, width: 60),
                    const SizedBox(height: 8),
                    const ClimbSkeleton(height: 70, borderRadius: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // List Skeleton
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: const ClimbSkeleton(height: 70, borderRadius: 16),
            ),
          ),
        ),
      ],
    );
  }
}
