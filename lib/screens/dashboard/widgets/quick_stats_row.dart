import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/leaderboard/leaderboard_cubit.dart';
import '../../../cubits/leaderboard/leaderboard_state.dart';
import '../../../cubits/profile/profile_cubit.dart';
import '../../../cubits/profile/profile_state.dart';
import '../../../cubits/task/task_cubit.dart';
import '../../../cubits/task/task_state.dart';
import '../../../widgets/climb_ui.dart';

class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        return BlocBuilder<TaskCubit, TaskState>(
          builder: (context, taskState) {
            return BlocBuilder<LeaderboardCubit, LeaderboardState>(
              builder: (context, leaderboardState) {
                final userId = profileState.user.id;
                final rank = leaderboardState.entries
                    .where((e) => e.userId == userId)
                    .firstOrNull
                    ?.rank;

                return AppCard(
                  child: StatRow(
                    stats: [
                      StatBlock(
                        value: '${taskState.todayCompletedCount}/${taskState.todayTotalCount}',
                        label: 'Done today',
                      ),
                      StatBlock(
                        value: '+${taskState.todayXPEarned}',
                        label: 'XP today',
                      ),
                      StatBlock(
                        value: rank != null ? '#$rank' : '–',
                        label: 'Rank',
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
