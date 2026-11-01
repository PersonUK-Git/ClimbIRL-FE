import 'package:flutter/material.dart';
import '../../../../widgets/climb_skeleton.dart';

class TaskCardSkeleton extends StatelessWidget {
  const TaskCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ClimbSkeleton.circle(size: 44),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClimbSkeleton(height: 14, width: 170),
                SizedBox(height: 8),
                ClimbSkeleton(height: 11, width: 90),
              ],
            ),
          ),
          ClimbSkeleton(height: 14, width: 36),
        ],
      ),
    );
  }
}
