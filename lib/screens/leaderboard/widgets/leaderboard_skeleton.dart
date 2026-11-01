import 'package:flutter/material.dart';
import '../../../../widgets/climb_skeleton.dart';

class LeaderboardSkeleton extends StatelessWidget {
  const LeaderboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [
        ClimbSkeleton(height: 190, width: double.infinity, borderRadius: 24),
        SizedBox(height: 10),
        ClimbSkeleton(height: 320, width: double.infinity, borderRadius: 24),
      ],
    );
  }
}
