import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/xp_utils.dart';
import '../../../cubits/profile/profile_cubit.dart';
import '../../../cubits/profile/profile_state.dart';
import '../../../widgets/climb_ui.dart';
import '../../../widgets/dot_climb.dart';

class XPProgressCard extends StatelessWidget {
  const XPProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final user = state.user;
        final xpToNext = XPUtils.xpToNextLevel(user.totalXP);

        return Column(
          children: [
            Text(
              'Level ${user.level}  ·  ${user.title}',
              style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            DotNumber(formatNumber(user.totalXP), height: 62),
            const SizedBox(height: 14),
            Text(
              xpToNext > 0
                  ? '${formatNumber(xpToNext)} XP to level ${user.level + 1}'
                  : 'Summit reached',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 26),
            DotClimb(progress: XPUtils.ascentProgress(user.totalXP)),
          ],
        );
      },
    );
  }
}
