import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../cubits/profile/profile_state.dart';
import '../../models/achievement_model.dart';
import '../../widgets/xp_bar.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final categories = ['All', 'Tasks', 'Streaks', 'Social', 'Special'];

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final filtered = _selectedCategory == 'All'
            ? state.achievements
            : state.achievements
                .where((a) => a.category == _selectedCategory)
                .toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Achievements',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Category filter
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primary
                                : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.2),
                                  ),
                          ),
                          child: Text(
                            cat,
                            style: tt.labelMedium?.copyWith(
                              color: isSelected
                                  ? cs.onPrimary
                                  : cs.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Achievements grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _AchievementCard(
                      achievement: filtered[index],
                      onTap: () =>
                          _showAchievementDetail(context, filtered[index]),
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          duration: 400.ms,
                        )
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                          delay: Duration(milliseconds: 50 * index),
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAchievementDetail(
      BuildContext context, AchievementModel achievement) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? _getRarityColor(achievement.rarity)
                        .withValues(alpha: 0.15)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getAchievementIcon(achievement.iconName),
                size: 36,
                color: achievement.isUnlocked
                    ? _getRarityColor(achievement.rarity)
                    : cs.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 16),
            // Rarity
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getRarityColor(achievement.rarity)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                achievement.rarity,
                style: tt.labelSmall?.copyWith(
                  color: _getRarityColor(achievement.rarity),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              achievement.title,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Progress
            if (!achievement.isUnlocked) ...[
              XPBar(
                progress: achievement.progress,
                height: 10,
                gradientColors: [
                  _getRarityColor(achievement.rarity),
                  _getRarityColor(achievement.rarity).withValues(alpha: 0.6),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${achievement.current} / ${achievement.target}',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              const SizedBox(height: 8),
              Text(
                'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementModel achievement;
  final VoidCallback? onTap;

  const _AchievementCard({
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rarityColor = _getRarityColor(achievement.rarity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: achievement.isUnlocked
                ? rarityColor.withValues(alpha: 0.3)
                : cs.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? rarityColor.withValues(alpha: 0.12)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getAchievementIcon(achievement.iconName),
                size: 26,
                color: achievement.isUnlocked
                    ? rarityColor
                    : cs.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              achievement.title,
              style: tt.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: achievement.isUnlocked ? null : cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              achievement.description,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Progress or status
            if (achievement.isUnlocked)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Unlocked',
                      style: tt.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  XPBar(
                    progress: achievement.progress,
                    height: 6,
                    gradientColors: [
                      rarityColor,
                      rarityColor.withValues(alpha: 0.5),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(achievement.progress * 100).toInt()}%',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Color _getRarityColor(String rarity) {
  switch (rarity) {
    case 'Common':
      return Colors.grey;
    case 'Rare':
      return Colors.blue;
    case 'Epic':
      return Colors.purple;
    case 'Legendary':
      return Colors.amber;
    default:
      return Colors.grey;
  }
}

IconData _getAchievementIcon(String iconName) {
  switch (iconName) {
    case 'rocket_launch':
      return Icons.rocket_launch_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'military_tech':
      return Icons.military_tech_rounded;
    case 'workspace_premium':
      return Icons.workspace_premium_rounded;
    case 'local_fire_department':
      return Icons.local_fire_department_rounded;
    case 'whatshot':
      return Icons.whatshot_rounded;
    case 'shield':
      return Icons.shield_rounded;
    case 'diamond':
      return Icons.diamond_rounded;
    case 'group_add':
      return Icons.group_add_rounded;
    case 'emoji_events':
      return Icons.emoji_events_rounded;
    case 'leaderboard':
      return Icons.leaderboard_rounded;
    case 'wb_sunny':
      return Icons.wb_sunny_rounded;
    case 'nightlight':
      return Icons.nightlight_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'auto_awesome':
      return Icons.auto_awesome_rounded;
    case 'rocket':
      return Icons.rocket_rounded;
    default:
      return Icons.emoji_events_rounded;
  }
}
