import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/notification_service.dart';
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
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ScrollController _scrollController;
  bool _isSnapping = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isSnapping = false;
              }
              if (_isSnapping) return false;
              if (notification is ScrollEndNotification) {
                final double offset = _scrollController.offset;
                final double maxScroll = 328.0; // maxExtent (400.0) - minExtent (72.0)
                if (offset > 0.5 && offset < maxScroll - 0.5) {
                  final double target = offset < maxScroll / 2 ? 0.0 : maxScroll;
                  _isSnapping = true;
                  Future.microtask(() {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        target,
                        duration: const Duration(milliseconds: 375),
                        curve: Curves.fastOutSlowIn,
                      ).then((_) {
                        _isSnapping = false;
                      });
                    } else {
                      _isSnapping = false;
                    }
                  });
                }
              }
              return false;
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ProfileHeaderDelegate(
                    user: user,
                    progress: progress,
                    context: context,
                    cs: cs,
                    tt: tt,
                    themeCubit: context.read<ThemeCubit>(),
                    authCubit: context.read<AuthCubit>(),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
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
                              value: '${state.unlockedAchievements.length}',
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
                            color: cs.outlineVariant.withValues(alpha: 0.2),
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
                                  maxY:
                                      (user.weeklyXP.isEmpty
                                              ? 100
                                              : user.weeklyXP.reduce(
                                                      (a, b) => a > b ? a : b,
                                                    ) *
                                                    1.3)
                                          .toDouble(),
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (_) => cs.inverseSurface,
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) {
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
                                            'S',
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
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
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
                                          toY: user.weeklyXP[index].toDouble(),
                                          color: index == 6
                                              ? cs.primary
                                              : cs.primary.withValues(
                                                  alpha: 0.4,
                                                ),
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
                              color: cs.outlineVariant.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.12),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            icon: Icons.notifications_rounded,
                            label: 'Notification Time',
                            onTap: () => _showNotificationTimePicker(context),
                          ),
                          _MenuTile(
                            icon: Icons.description_rounded,
                            label: 'Privacy Policy',
                            onTap: () => _launchURL(ApiConstants.privacyPolicy),
                          ),
                          _MenuTile(
                            icon: Icons.gavel_rounded,
                            label: 'Terms of Service',
                            onTap: () =>
                                _launchURL(ApiConstants.termsOfService),
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
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      );
      },
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final UserModel user;
  final double progress;
  final BuildContext context;
  final ColorScheme cs;
  final TextTheme tt;
  final ThemeCubit themeCubit;
  final AuthCubit authCubit;

  _ProfileHeaderDelegate({
    required this.user,
    required this.progress,
    required this.context,
    required this.cs,
    required this.tt,
    required this.themeCubit,
    required this.authCubit,
  });

  @override
  double get maxExtent => 400.0;

  @override
  double get minExtent => 72.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final width = MediaQuery.of(context).size.width;

    // Fade values
    final double cardOpacity = (1.0 - t * 2.5).clamp(0.0, 1.0);

    // Avatar layout:
    // Expanded diameter: 72, collapsed: 36 (radius 36 to 18)
    // Expanded ring size: 88, collapsed: 44
    final double expandedAvatarSize = 72.0;
    final double collapsedAvatarSize = 36.0;
    final double avatarSize =
        expandedAvatarSize + (collapsedAvatarSize - expandedAvatarSize) * t;

    final double expandedRingSize = 88.0;
    final double collapsedRingSize = 44.0;
    final double ringSize =
        expandedRingSize + (collapsedRingSize - expandedRingSize) * t;

    // Y position of avatar:
    // Expanded: Y=92 (aligns with card top Y=72 + card padding top=20)
    // Collapsed: Y=14 (centered in top bar)
    final double avatarY = 92.0 + (14.0 - 92.0) * t;

    // X position of avatar:
    // Expanded: centered -> (width - ringSize) / 2
    // Collapsed: left aligned -> 20
    final double expandedAvatarX = (width - expandedRingSize) / 2;
    final double collapsedAvatarX = 20.0;
    final double avatarX =
        expandedAvatarX + (collapsedAvatarX - expandedAvatarX) * t;

    // "Profile" text layout:
    // Expanded: X=20, Y=16
    // Collapsed: X = 20 + collapsedRingSize (44) + 12 = 76, Y = 22 (centered with avatar Y=14 + ringSize/2=36)
    final double expandedTextX = 20.0;
    final double collapsedTextX = 20.0 + collapsedRingSize + 12.0;
    final double textX = expandedTextX + (collapsedTextX - expandedTextX) * t;

    final double expandedTextY = 16.0;
    final double collapsedTextY = 22.0;
    final double textY = expandedTextY + (collapsedTextY - expandedTextY) * t;

    final double expandedFontSize = 28.0; // headlineMedium
    final double collapsedFontSize = 20.0; // titleLarge
    final double fontSize =
        expandedFontSize + (collapsedFontSize - expandedFontSize) * t;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          // 1. Card containing user stats/info (fades out as we scroll)
          if (cardOpacity > 0.0)
            Positioned(
              left: 32,
              right: 32,
              top: 72,
              child: Opacity(
                opacity: cardOpacity,
                child: Container(
                  padding: const EdgeInsets.all(
                    20,
                  ), // restored original card padding
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Spacer matching the avatar + ring size and its original spacing
                      const SizedBox(height: 88 + 14),
                      Text(
                        user.name,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            colors: [cs.primary, cs.tertiary],
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
                      const SizedBox(height: 10), // restored original spacing
                      OutlinedButton.icon(
                        onPressed: () => _showEditProfileSheet(context, user),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14), // restored original spacing
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
                ),
              ),
            ),

          // 2. Avatar + Level Ring (moves and scales)
          Positioned(
            left: avatarX,
            top: avatarY,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: lerpDouble(4.0, 2.0, t)!,
                    backgroundColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
                CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: user.avatarUrl.isNotEmpty
                      ? NetworkImage(user.avatarUrl)
                      : null,
                  child: user.avatarUrl.isEmpty
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: tt.headlineSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: lerpDouble(24.0, 12.0, t)!,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),

          // 3. "Profile" Title text (moves and shrinks)
          Positioned(
            left: textX,
            top: textY,
            child: Text(
              'Profile',
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
              ),
            ),
          ),

          // 4. Action buttons (top right)
          Positioned(
            right: 20,
            top: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                              authCubit.logout();
                            },
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.grey),
                ),
                // Theme toggle
                IconButton(
                  onPressed: () => themeCubit.toggleTheme(),
                  icon: BlocBuilder<ThemeCubit, ThemeState>(
                    bloc: themeCubit,
                    builder: (context, themeState) {
                      final isDark =
                          themeState.themeMode == ThemeMode.dark ||
                          (themeState.themeMode == ThemeMode.system &&
                              MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark);
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          key: ValueKey(isDark),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.user != user ||
        oldDelegate.progress != progress ||
        oldDelegate.cs != cs ||
        oldDelegate.tt != tt;
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

void _showNotificationTimePicker(BuildContext context) async {
  final profileCubit = context.read<ProfileCubit>();
  final user = profileCubit.state.user;

  final parts = user.notificationTime.split(':');
  final utcHour = int.tryParse(parts[0]) ?? 8;
  final utcMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

  final now = DateTime.now();
  final utcDateTime = DateTime.utc(
    now.year,
    now.month,
    now.day,
    utcHour,
    utcMinute,
  );
  final localDateTime = utcDateTime.toLocal();

  final initialTime = TimeOfDay(
    hour: localDateTime.hour,
    minute: localDateTime.minute,
  );

  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: initialTime,
  );

  if (picked != null) {
    final pickedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    final utcDateTime = pickedDateTime.toUtc();
    final timeStr =
        '${utcDateTime.hour.toString().padLeft(2, '0')}:${utcDateTime.minute.toString().padLeft(2, '0')}';

    final updatedUser = user.copyWith(notificationTime: timeStr);
    final success = await profileCubit.updateUser(updatedUser);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification time updated to ${picked.format(context)}',
          ),
        ),
      );
    }
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
              builder: (ctx) =>
                  const Center(child: CircularProgressIndicator()),
            );

            final success = await ApiRepository().deleteAccount();

            if (!context.mounted) return;
            Navigator.pop(context); // hide loading

            if (success) {
              context.read<OnboardingCubit>().resetOnboarding();
              context.read<AuthCubit>().logout();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to delete account. Please try again.'),
                ),
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
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
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
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showEditProfileSheet(BuildContext context, UserModel user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<ProfileCubit>(),
      child: _EditProfileSheet(user: user),
    ),
  );
}

class _EditProfileSheet extends StatefulWidget {
  final UserModel user;

  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  File? _pickedImage;
  String? _avatarBase64;
  bool _isLoading = false;

  // Username Availability State
  bool? _isUsernameAvailable = true;
  bool _isCheckingUsername = false;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    if (_usernameDebounce?.isActive ?? false) _usernameDebounce!.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    if (trimmed.toLowerCase() == widget.user.username.toLowerCase()) {
      setState(() {
        _isUsernameAvailable = true;
        _isCheckingUsername = false;
      });
      return;
    }

    if (trimmed.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await ApiRepository().isUsernameAvailable(
        trimmed,
        excludeUserId: widget.user.id,
      );
      if (mounted) {
        setState(() {
          _isUsernameAvailable = available;
          _isCheckingUsername = false;
        });
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedImage = file;
          _avatarBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final updatedUser = widget.user.copyWith(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
    );

    final success = await context.read<ProfileCubit>().updateUser(
      updatedUser,
      avatarBase64: _avatarBase64,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Edit Profile',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: cs.primaryContainer,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (widget.user.avatarUrl.isNotEmpty
                                ? NetworkImage(widget.user.avatarUrl)
                                      as ImageProvider
                                : null),
                      child:
                          _pickedImage == null && widget.user.avatarUrl.isEmpty
                          ? Text(
                              widget.user.name.isNotEmpty
                                  ? widget.user.name[0].toUpperCase()
                                  : 'U',
                              style: tt.headlineLarge?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Name cannot be empty'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                onChanged: _onUsernameChanged,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  suffixIcon: _isCheckingUsername
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_isUsernameAvailable != null
                            ? Icon(
                                _isUsernameAvailable!
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: _isUsernameAvailable!
                                    ? Colors.green
                                    : Colors.red,
                              )
                            : null),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText:
                      _isUsernameAvailable == true &&
                          _usernameController.text.trim().toLowerCase() !=
                              widget.user.username.toLowerCase()
                      ? 'Username is available! '
                      : null,
                  helperStyle: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                  errorText: _isUsernameAvailable == false
                      ? 'Username is already taken'
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Username cannot be empty';
                  if (val.trim().length < 3)
                    return 'Username must be at least 3 characters';
                  if (_isUsernameAvailable == false)
                    return 'Username is already taken';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed:
                      _isLoading ||
                          _isCheckingUsername ||
                          _isUsernameAvailable != true
                      ? null
                      : _save,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
