import 'package:flutter/material.dart';
import '../../../../widgets/climb_skeleton.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // Greeting & Avatar
          Row(
            children: [
              ClimbSkeleton.circle(size: 42),
              SizedBox(width: 12),
              ClimbSkeleton(height: 28, width: 110),
            ],
          ),
          SizedBox(height: 30),

          // XP and climb
          ClimbSkeleton(height: 14, width: 130),
          SizedBox(height: 14),
          ClimbSkeleton(height: 62, width: 220),
          SizedBox(height: 40),
          ClimbSkeleton(height: 92, width: double.infinity),
          SizedBox(height: 26),

          // Cards
          ClimbSkeleton(height: 88, width: double.infinity, borderRadius: 24),
          SizedBox(height: 10),
          ClimbSkeleton(height: 130, width: double.infinity, borderRadius: 24),
          SizedBox(height: 10),
          ClimbSkeleton(height: 220, width: double.infinity, borderRadius: 24),
        ],
      ),
    );
  }
}
