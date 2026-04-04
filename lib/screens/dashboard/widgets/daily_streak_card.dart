import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/profile/profile_cubit.dart';
import '../../../cubits/profile/profile_state.dart';
import '../../../core/theme/app_colors.dart';

class DailyStreakCard extends StatelessWidget {
  const DailyStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final user = state.user;
        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

        return Container(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.streak.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.streak,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.currentStreak} Day Streak',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Best: ${user.longestStreak} days',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.streak,
                    size: 32,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final active = user.streakDays[index];
                  return Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.streak.withValues(alpha: 0.15)
                              : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: active
                              ? Border.all(
                                  color: AppColors.streak,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Center(
                          child: active
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: AppColors.streak,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        days[index],
                        style: tt.labelSmall?.copyWith(
                          color: active
                              ? AppColors.streak
                              : cs.onSurfaceVariant,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
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
