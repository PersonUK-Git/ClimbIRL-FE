import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../cubits/leaderboard/leaderboard_cubit.dart';
import '../../cubits/leaderboard/leaderboard_state.dart';
import '../../models/leaderboard_entry_model.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Leaderboard',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Period Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: LeaderboardPeriod.values.map((period) {
                      final isSelected = state.period == period;
                      final label = switch (period) {
                        LeaderboardPeriod.weekly => 'Weekly',
                        LeaderboardPeriod.monthly => 'Monthly',
                        LeaderboardPeriod.allTime => 'All Time',
                      };
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => context
                              .read<LeaderboardCubit>()
                              .setPeriod(period),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).cardTheme.color
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            cs.shadow.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: tt.labelMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? cs.onSurface
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Podium
              if (state.top3.length >= 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _PodiumSection(top3: state.top3),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),

              const SizedBox(height: 20),

              // Rest of rankings
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: state.restOfList.length,
                  itemBuilder: (context, index) {
                    final entry = state.restOfList[index];
                    final isCurrentUser =
                        entry.userId == state.currentUserId;
                    return _RankCard(
                      entry: entry,
                      isCurrentUser: isCurrentUser,
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          duration: 400.ms,
                        )
                        .slideX(
                          begin: 0.03,
                          end: 0,
                          delay: Duration(milliseconds: 50 * index),
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        );
                  },
                ),
              ),

              // Current user position
              if (state.currentUserEntry != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    border: Border(
                      top: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: _RankCard(
                    entry: state.currentUserEntry!,
                    isCurrentUser: true,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(
                      begin: 0.5,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _PodiumSection extends StatelessWidget {
  final List<LeaderboardEntryModel> top3;

  const _PodiumSection({required this.top3});

  @override
  Widget build(BuildContext context) {
    // Reorder: 2nd, 1st, 3rd
    final second = top3[1];
    final first = top3[0];
    final third = top3[2];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumSlot(entry: second, height: 90, medal: '🥈')),
        const SizedBox(width: 8),
        Expanded(child: _PodiumSlot(entry: first, height: 120, medal: '🥇')),
        const SizedBox(width: 8),
        Expanded(child: _PodiumSlot(entry: third, height: 70, medal: '🥉')),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final double height;
  final String medal;

  const _PodiumSlot({
    required this.entry,
    required this.height,
    required this.medal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isFirst = medal == '🥇';

    return Column(
      children: [
        // Avatar
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: isFirst ? 30 : 24,
              backgroundColor: cs.primaryContainer,
              child: Text(
                entry.name[0],
                style: tt.titleMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: isFirst ? 20 : 16,
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              child: Text(medal, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          entry.name.split(' ').first,
          style: tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${entry.totalXP} XP',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // Podium bar
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isFirst
                  ? [cs.primary, cs.primary.withValues(alpha: 0.7)]
                  : [
                      cs.primaryContainer,
                      cs.primaryContainer.withValues(alpha: 0.7),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: tt.titleMedium?.copyWith(
                color: isFirst ? cs.onPrimary : cs.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? cs.primary.withValues(alpha: 0.08)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser
              ? cs.primary.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isCurrentUser ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isCurrentUser
                ? cs.primary.withValues(alpha: 0.2)
                : cs.primaryContainer,
            child: Text(
              entry.name[0],
              style: tt.labelMedium?.copyWith(
                color: isCurrentUser
                    ? cs.primary
                    : cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser ? cs.primary : null,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Level ${entry.level}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalXP}',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'XP',
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
