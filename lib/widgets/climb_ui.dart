import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Formats a number with thousands separators, such as 12,400.
String formatNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Small muted label for a value or a group.
class MutedLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const MutedLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelMedium?.copyWith(
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Rounded surface that groups related content.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

/// Title block at the top of a tab, with optional subtitle and trailing widget.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.headlineLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  MutedLabel(subtitle!),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Pill-shaped filter tabs; the selected one is filled.
class PillTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const PillTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(labels.length, (index) {
          final isSelected = index == selectedIndex;
          return Semantics(
            button: true,
            selected: isSelected,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? cs.onSurface : cs.surface,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  labels[index],
                  style: tt.labelLarge?.copyWith(
                    color: isSelected ? cs.surface : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Round user picture, falling back to an initial.
class UserAvatar extends StatelessWidget {
  final String name;
  final String url;
  final double size;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.name,
    required this.url,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? cs.surfaceContainerHighest,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTextStyles.display(size * 0.4, color: cs.onSurface),
            )
          : null,
    );
  }
}

/// Four dots that show a difficulty, one filled for Easy up to four for Epic.
class DifficultyDots extends StatelessWidget {
  final String difficulty;
  final double dotSize;
  final Color? color;

  const DifficultyDots({
    super.key,
    required this.difficulty,
    this.dotSize = 5,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final level = AppColors.difficultyLevel(difficulty);
    final filled = color ?? cs.onSurface;

    return Semantics(
      label: difficulty,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (index) {
          return Container(
            width: dotSize,
            height: dotSize,
            margin: EdgeInsets.only(left: index == 0 ? 0 : dotSize * 0.55),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index < level ? filled : cs.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          );
        }),
      ),
    );
  }
}

/// A difficulty token: a round chip holding its difficulty dots.
class TokenMark extends StatelessWidget {
  final String difficulty;
  final double size;
  final bool dimmed;

  const TokenMark({
    super.key,
    required this.difficulty,
    this.size = 40,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: DifficultyDots(difficulty: difficulty, dotSize: size * 0.1),
      ),
    );
  }
}

/// A number above a small label.
class StatBlock extends StatelessWidget {
  final String value;
  final String label;

  const StatBlock({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 3),
        MutedLabel(label),
      ],
    );
  }
}

/// A row of equally wide [StatBlock]s.
class StatRow extends StatelessWidget {
  final List<StatBlock> stats;

  const StatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final stat in stats) Expanded(child: stat),
      ],
    );
  }
}
