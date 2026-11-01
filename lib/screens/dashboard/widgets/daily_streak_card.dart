import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/profile/profile_cubit.dart';
import '../../../cubits/profile/profile_state.dart';
import '../../../widgets/climb_ui.dart';

class DailyStreakCard extends StatelessWidget {
  const DailyStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final user = state.user;
        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        final today = DateTime.now().weekday - 1;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.currentStreak == 1
                          ? '1 day streak'
                          : '${user.currentStreak} day streak',
                      style: tt.titleMedium,
                    ),
                  ),
                  MutedLabel('Best ${user.longestStreak}'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(7, (index) {
                  final active = index < user.streakDays.length && user.streakDays[index];
                  final isToday = index == today;

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: active ? cs.onSurface : cs.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: isToday && !active
                                ? Border.all(color: cs.onSurface, width: 1.25)
                                : null,
                          ),
                          child: active
                              ? Icon(Icons.check_rounded, size: 16, color: cs.surface)
                              : null,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          days[index],
                          style: tt.labelMedium?.copyWith(
                            color: isToday ? cs.onSurface : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
