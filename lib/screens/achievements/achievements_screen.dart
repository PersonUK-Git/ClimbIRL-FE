import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../cubits/profile/profile_state.dart';
import '../../models/achievement_model.dart';
import '../../widgets/climb_ui.dart';
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
    final categories = ['All', 'Tasks', 'Streaks', 'Social', 'Special'];

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final filtered = _selectedCategory == 'All'
            ? state.achievements
            : state.achievements
                .where((a) => a.category == _selectedCategory)
                .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Achievements'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Category filter
              PillTabs(
                labels: categories,
                selectedIndex: categories.indexOf(_selectedCategory),
                onSelected: (index) =>
                    setState(() => _selectedCategory = categories[index]),
              ),
              const SizedBox(height: 12),

              // Achievements list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _AchievementCard(
                      achievement: filtered[index],
                      onTap: () =>
                          _showAchievementDetail(context, filtered[index]),
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
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: double.infinity),
            _AchievementIcon(achievement: achievement, size: 76),
            const SizedBox(height: 16),
            Text(
              achievement.title,
              style: tt.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              achievement.description,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            MutedLabel(
              achievement.rarity,
              color: AppColors.rarityColor(achievement.rarity, Theme.of(context).brightness),
            ),
            const SizedBox(height: 20),
            // Progress
            if (!achievement.isUnlocked) ...[
              XPBar(progress: achievement.progress),
              const SizedBox(height: 8),
              MutedLabel('${achievement.current} of ${achievement.target}'),
            ],
            if (achievement.isUnlocked && achievement.unlockedAt != null)
              MutedLabel('Unlocked ${_formatDate(achievement.unlockedAt!)}'),
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

class _AchievementIcon extends StatelessWidget {
  final AchievementModel achievement;
  final double size;

  const _AchievementIcon({required this.achievement, required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final unlocked = achievement.isUnlocked;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: unlocked ? cs.onSurface : cs.surfaceContainerHighest,
      ),
      child: Icon(
        _getAchievementIcon(achievement.iconName),
        size: size * 0.48,
        color: unlocked ? cs.surface : cs.onSurfaceVariant,
      ),
    );
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _AchievementIcon(achievement: achievement, size: 44),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              achievement.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleSmall?.copyWith(fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 8),
                          MutedLabel(
                            achievement.rarity,
                            color: achievement.rarity == 'Legendary' ? cs.secondary : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        achievement.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      if (!achievement.isUnlocked) ...[
                        const SizedBox(height: 9),
                        XPBar(progress: achievement.progress, height: 3),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _getAchievementIcon(String iconName) {
  switch (iconName) {
    case 'rocket_launch':
      return Icons.rocket_launch_outlined;
    case 'bolt':
      return Icons.bolt_outlined;
    case 'military_tech':
      return Icons.military_tech_outlined;
    case 'workspace_premium':
      return Icons.workspace_premium_outlined;
    case 'local_fire_department':
      return Icons.local_fire_department_outlined;
    case 'whatshot':
      return Icons.whatshot_outlined;
    case 'shield':
      return Icons.shield_outlined;
    case 'diamond':
      return Icons.diamond_outlined;
    case 'group_add':
      return Icons.group_add_outlined;
    case 'emoji_events':
      return Icons.emoji_events_outlined;
    case 'leaderboard':
      return Icons.leaderboard_outlined;
    case 'wb_sunny':
      return Icons.wb_sunny_outlined;
    case 'nightlight':
      return Icons.nightlight_outlined;
    case 'star':
      return Icons.star_outline_rounded;
    case 'auto_awesome':
      return Icons.auto_awesome_outlined;
    case 'rocket':
      return Icons.rocket_outlined;
    default:
      return Icons.emoji_events_outlined;
  }
}
