import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Chip showing task difficulty with appropriate color.
class DifficultyChip extends StatelessWidget {
  final String difficulty;
  final bool showXP;

  const DifficultyChip({
    super.key,
    required this.difficulty,
    this.showXP = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.difficultyColor(difficulty);
    final xp = AppColors.difficultyXP(difficulty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            showXP ? '$difficulty · ${xp}XP' : difficulty,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
