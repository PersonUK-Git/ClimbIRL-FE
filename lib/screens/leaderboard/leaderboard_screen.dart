import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../cubits/leaderboard/leaderboard_cubit.dart';
import '../../cubits/leaderboard/leaderboard_state.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../models/leaderboard_entry_model.dart';
import 'widgets/leaderboard_skeleton.dart';

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

              if (state.status == LeaderboardStatus.loading ||
                  state.status == LeaderboardStatus.initial)
                const Expanded(child: LeaderboardSkeleton())
              else ...[
                const SizedBox(height: 20),

                // Podium
                if (state.top3.length >= 3)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        final currentUserId = authState is AuthAuthenticated 
                            ? authState.user.id 
                            : state.currentUserId;
                        return _PodiumSection(
                          top3: state.top3,
                          currentUserId: currentUserId,
                        );
                      },
                    ),
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
                      return BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, authState) {
                          final currentUserId = authState is AuthAuthenticated 
                              ? authState.user.id 
                              : state.currentUserId;
                          final isCurrentUser = entry.userId == currentUserId;
                          
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
                      );
                    },
                  ),
                ),

                // Current user position
                if (state.entries.isNotEmpty)
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      final currentUserId = authState is AuthAuthenticated 
                          ? authState.user.id 
                          : state.currentUserId;
                      
                      // Find entry manually to be safe
                      final currentUserEntry = state.entries.where((e) => e.userId == currentUserId).firstOrNull;
                      
                      if (currentUserEntry == null) return const SizedBox.shrink();

                      return ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                              border: Border(
                                top: BorderSide(
                                  color: cs.outlineVariant.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            child: _RankCard(
                              entry: currentUserEntry,
                              isCurrentUser: true,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(
                            begin: 0.5,
                            end: 0,
                            duration: 500.ms,
                            curve: Curves.easeOutCubic,
                          );
                    },
                  ),
              ],
            ],
          ),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumSlot(
            entry: second,
            height: 90,
            medal: '🥈',
            isCurrentUser: second.userId == currentUserId,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumSlot(
            entry: first,
            height: 120,
            medal: '🥇',
            isCurrentUser: first.userId == currentUserId,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumSlot(
            entry: third,
            height: 70,
            medal: '🥉',
            isCurrentUser: third.userId == currentUserId,
          ),
        ),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final double height;
  final String medal;
  final bool isCurrentUser;

  const _PodiumSlot({
    required this.entry,
    required this.height,
    required this.medal,
    this.isCurrentUser = false,
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
              backgroundImage: entry.avatarUrl.isNotEmpty
                  ? NetworkImage(entry.avatarUrl)
                  : null,
              child: entry.avatarUrl.isEmpty
                  ? Text(
                      entry.name[0],
                      style: tt.titleMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: isFirst ? 20 : 16,
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: -6,
              child: Text(medal, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isCurrentUser)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              'YOU',
              style: tt.labelSmall?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 8,
                letterSpacing: 0.5,
              ),
            ),
          ),
        Text(
          entry.name.split(' ').first,
          style: tt.labelMedium?.copyWith(
            fontWeight: isCurrentUser ? FontWeight.w900 : FontWeight.w700,
            color: isCurrentUser ? cs.primary : null,
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
            boxShadow: isCurrentUser
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ]
                : null,
            border: isCurrentUser
                ? Border.all(color: cs.primary.withValues(alpha: 0.5), width: 1.5)
                : null,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isCurrentUser
            ? LinearGradient(
                colors: [
                  cs.primary,
                  cs.primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isCurrentUser ? null : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isCurrentUser)
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (isCurrentUser)
                Container(
                  width: 3,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isCurrentUser ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isCurrentUser
                ? cs.onPrimary.withValues(alpha: 0.2)
                : cs.primaryContainer,
            backgroundImage: entry.avatarUrl.isNotEmpty
                ? NetworkImage(entry.avatarUrl)
                : null,
            child: entry.avatarUrl.isEmpty
                ? Text(
                    entry.name[0],
                    style: tt.labelMedium?.copyWith(
                      color: isCurrentUser
                          ? cs.onPrimary
                          : cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
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
                        color: isCurrentUser ? cs.onPrimary : null,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? cs.onPrimary : null,
                          gradient: isCurrentUser ? null : LinearGradient(
                            colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'YOU',
                          style: tt.labelSmall?.copyWith(
                            color: isCurrentUser ? cs.primary : cs.onPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Level ${entry.level}',
                  style: tt.bodySmall?.copyWith(
                    color: isCurrentUser
                        ? cs.onPrimary.withValues(alpha: 0.8)
                        : cs.onSurfaceVariant,
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
                  color: isCurrentUser ? cs.onPrimary : null,
                ),
              ),
              Text(
                'XP',
                style: tt.labelSmall?.copyWith(
                  color: isCurrentUser ? cs.onPrimary.withValues(alpha: 0.8) : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }
}
