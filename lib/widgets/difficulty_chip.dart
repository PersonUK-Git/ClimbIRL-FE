import 'package:flutter/material.dart';
import 'climb_ui.dart';

/// Difficulty dots beside the difficulty name.
class DifficultyChip extends StatelessWidget {
  final String difficulty;

  const DifficultyChip({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DifficultyDots(
          difficulty: difficulty,
          dotSize: 4.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          difficulty,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
