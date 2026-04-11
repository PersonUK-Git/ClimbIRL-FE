import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../cubits/profile/profile_state.dart';
import '../../cubits/theme/theme_cubit.dart';
import '../../cubits/theme/theme_state.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../core/utils/xp_utils.dart';
import '../../widgets/xp_bar.dart';
import '../achievements/achievements_screen.dart';
import '../../core/network/api_constants.dart';
import '../../data/repositories/api_repository.dart';
import '../../cubits/onboarding/onboarding_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final user = state.user;
        final progress = XPUtils.levelProgress(user.totalXP);

        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      // Header with settings
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile',
                            style: tt.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Row(
                            children: [
                              // Logout button
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Logout'),
                                      content: const Text('Are you sure you want to logout?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            context.read<AuthCubit>().logout();
                                          },
                                          child: const Text('Logout', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.logout_rounded, color: Colors.grey),
                              ),
                              // Theme toggle
                              BlocBuilder<ThemeCubit, ThemeState>(
                                builder: (context, themeState) {
                                  final isDark =
                                      themeState.themeMode == ThemeMode.dark ||
                                          (themeState.themeMode ==
                                                  ThemeMode.system &&
                                              MediaQuery.of(context)
                                                      .platformBrightness ==
                                                  Brightness.dark);
                                  return IconButton(
                                    onPressed: () {
                                      context.read<ThemeCubit>().toggleTheme();
                                    },
                                    icon: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: Icon(
                                        isDark
                                            ? Icons.light_mode_rounded
                                            : Icons.dark_mode_rounded,
                                        key: ValueKey(isDark),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 20),

                      // Profile header card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                cs.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Avatar + Level Ring
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 88,
                                  height: 88,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 4,
                                    backgroundColor: cs
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                    valueColor:
                                        AlwaysStoppedAnimation(cs.primary),
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: cs.primaryContainer,
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: tt.headlineSmall?.copyWith(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              user.name,
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${user.username}',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Level badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cs.primary,
                                    cs.tertiary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Level ${user.level} · ${user.title}',
                                style: tt.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            XPBar(progress: progress, height: 8),
                            const SizedBox(height: 6),
                            Text(
                              '${user.totalXP} XP total · ${XPUtils.xpToNextLevel(user.totalXP)} to next level',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(
                            begin: 0.05,
                            end: 0,
                            delay: 100.ms,
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          ),

                      const SizedBox(height: 16),

                      // Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.bolt_rounded,
                              label: 'Total XP',
                              value: '${user.totalXP}',
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle_rounded,
                              label: 'Tasks Done',
                              value: '${user.tasksCompleted}',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.local_fire_department_rounded,
                              label: 'Streak',
                              value: '${user.currentStreak}d',
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.emoji_events_rounded,
                              label: 'Achievements',
                              value: '${user.achievementsUnlocked}',
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 250.ms, duration: 500.ms),

                      const SizedBox(height: 20),

                      // XP History Chart
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                cs.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'XP This Week',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 160,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: (user.weeklyXP.isEmpty
                                          ? 100
                                          : user.weeklyXP.reduce(
                                                  (a, b) => a > b ? a : b) *
                                              1.3)
                                      .toDouble(),
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (_) => cs.inverseSurface,
                                      getTooltipItem: (group, groupIndex,
                                          rod, rodIndex) {
                                        return BarTooltipItem(
                                          '${rod.toY.toInt()} XP',
                                          tt.labelSmall!.copyWith(
                                            color: cs.onInverseSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          const days = [
                                            'M',
                                            'T',
                                            'W',
                                            'T',
                                            'F',
                                            'S',
                                            'S'
                                          ];
                                          return Text(
                                            days[value.toInt()],
                                            style: tt.labelSmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          );
                                        },
                                        reservedSize: 20,
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(
                                    7,
                                    (index) => BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: user.weeklyXP[index]
                                              .toDouble(),
                                          color: index == 6
                                              ? cs.primary
                                              : cs.primary
                                                  .withValues(alpha: 0.4),
                                          width: 20,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

                      const SizedBox(height: 16),

                      // Achievements section
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<ProfileCubit>(),
                                child: const AchievementsScreen(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.outlineVariant
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Achievements',
                                      style: tt.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${state.unlockedAchievements.length} of ${state.achievements.length} unlocked',
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: cs.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 450.ms, duration: 500.ms),

                      const SizedBox(height: 20),

                      // Settings & Legal Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'Settings & Legal',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.description_rounded,
                            label: 'Privacy Policy',
                            onTap: () => _launchURL(ApiConstants.privacyPolicy),
                          ),
                          _MenuTile(
                            icon: Icons.gavel_rounded,
                            label: 'Terms of Service',
                            onTap: () => _launchURL(ApiConstants.termsOfService),
                          ),
                          _MenuTile(
                            icon: Icons.delete_forever_rounded,
                            label: 'Delete Account',
                            color: Colors.red,
                            onTap: () => _showDeleteConfirmation(context),
                          ),
                        ],
                      ).animate().fadeIn(delay: 550.ms, duration: 500.ms),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color ?? cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _launchURL(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

void _showDeleteConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
        'Are you absolutely sure? This will permanently delete your account, '
        'all your XP, levels, and task history. This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            // Show loading
            if (!context.mounted) return;
            
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(child: CircularProgressIndicator()),
            );

            final success = await ApiRepository().deleteAccount();
            
            if (!context.mounted) return;
            Navigator.pop(context); // hide loading

            if (success) {
              context.read<OnboardingCubit>().resetOnboarding();
              context.read<AuthCubit>().logout();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to delete account. Please try again.')),
              );
            }
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete Permanently'),
        ),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
