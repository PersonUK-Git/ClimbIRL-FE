import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_text_styles.dart';
import '../../cubits/leaderboard/leaderboard_cubit.dart';
import '../../cubits/leaderboard/leaderboard_state.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../models/leaderboard_entry_model.dart';
import '../../widgets/climb_ui.dart';
import '../../widgets/dot_climb.dart';
import 'widgets/leaderboard_skeleton.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final currentUserId = authState is AuthAuthenticated
                ? authState.user.id
                : state.currentUserId;
            final currentUserEntry = state.entries
                .where((e) => e.userId == currentUserId)
                .firstOrNull;
            final isLoading = state.status == LeaderboardStatus.loading ||
                state.status == LeaderboardStatus.initial;

            // The podium needs three climbers; otherwise everyone goes in the list.
            final hasPodium = state.top3.length >= 3;
            final rows = hasPodium ? state.restOfList : state.entries;

            // Pin the user's own row when it's too far down to see without scrolling.
            final pinned = currentUserEntry != null && currentUserEntry.rank > 8
                ? currentUserEntry
                : null;

            return SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenHeader(
                    title: 'Leaderboard',
                    subtitle: currentUserEntry != null
                        ? "You're #${currentUserEntry.rank}"
                        : 'Climbers ranked by XP',
                  ),
                  const SizedBox(height: 12),

                  // Period Tabs
                  PillTabs(
                    labels: const ['Weekly', 'Monthly', 'All time'],
                    selectedIndex: state.period.index,
                    onSelected: (index) => context
                        .read<LeaderboardCubit>()
                        .setPeriod(LeaderboardPeriod.values[index]),
                  ),
                  const SizedBox(height: 12),

                  if (isLoading)
                    const Expanded(child: LeaderboardSkeleton())
                  else if (state.entries.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No climbers yet',
                          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, pinned != null ? 10 : 120),
                        children: [
                          if (hasPodium) ...[
                            _PodiumSection(
                              top3: state.top3,
                              currentUserId: currentUserId,
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (rows.isNotEmpty)
                            AppCard(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                children: rows
                                    .map(
                                      (entry) => _RankCard(
                                        entry: entry,
                                        isCurrentUser: entry.userId == currentUserId,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Current user position
                    if (pinned != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: _RankCard(entry: pinned, isCurrentUser: true),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PodiumSection extends StatelessWidget {
  final List<LeaderboardEntryModel> top3;
  final String currentUserId;

  const _PodiumSection({
    required this.top3,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Reorder: 2nd, 1st, 3rd
    final second = top3[1];
    final first = top3[0];
    final third = top3[2];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 22, 10, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSlot(
              entry: second,
              isCurrentUser: second.userId == currentUserId,
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              entry: first,
              isFirst: true,
              isCurrentUser: first.userId == currentUserId,
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              entry: third,
              isCurrentUser: third.userId == currentUserId,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final bool isFirst;
  final bool isCurrentUser;

  const _PodiumSlot({
    required this.entry,
    this.isFirst = false,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        DotNumber(
          '${entry.rank}',
          height: isFirst ? 34 : 24,
          color: isFirst ? cs.secondary : cs.onSurface,
        ),
        const SizedBox(height: 14),
        UserAvatar(
          name: entry.name,
          url: entry.avatarUrl,
          size: isFirst ? 72 : 56,
        ),
        const SizedBox(height: 10),
        Text(
          isCurrentUser ? 'You' : entry.name.split(' ').first,
          style: tt.titleSmall,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        MutedLabel('${formatNumber(entry.totalXP)} XP'),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final bool isCurrentUser;

  const _RankCard({
    required this.entry,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '${entry.rank}',
              style: AppTextStyles.display(
                17,
                color: isCurrentUser ? cs.secondary : cs.onSurfaceVariant,
                height: 1,
              ),
            ),
          ),
          UserAvatar(name: entry.name, url: entry.avatarUrl, size: 42),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? 'You' : entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                MutedLabel('Level ${entry.level}'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // XP
          Text('${formatNumber(entry.totalXP)} XP', style: tt.titleSmall),
        ],
      ),
    );
  }
}
