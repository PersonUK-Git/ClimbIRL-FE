import 'package:flutter/material.dart';
import '../../../../widgets/climb_skeleton.dart';

class TaskCardSkeleton extends StatelessWidget {
  const TaskCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
          ),
        ),
        child: Row(
          children: [
            const ClimbSkeleton(height: 24, width: 24, borderRadius: 6),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ClimbSkeleton(height: 16, width: 150),
                  const SizedBox(height: 8),
                  const ClimbSkeleton(height: 12, width: 100),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const ClimbSkeleton(height: 24, width: 60, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}
