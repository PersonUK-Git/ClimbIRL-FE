import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/task/task_cubit.dart';
import '../../../cubits/task/task_state.dart';
import '../../../cubits/profile/profile_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/difficulty_chip.dart';

class TodayTasksSection extends StatelessWidget {
  const TodayTasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final tasks = state.todayTasks;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Tasks",
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${state.todayCompletedCount} of ${state.todayTotalCount}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 48,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tasks for today',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...tasks.map((task) {
                final categoryIcon =
                    _getCategoryIcon(task.category);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: task.isCompleted
                            ? AppColors.success.withValues(alpha: 0.3)
                            : cs.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        GestureDetector(
                          onTap: () {
                            final xpDelta = context
                                .read<TaskCubit>()
                                .toggleTask(task.id);
                            context.read<ProfileCubit>().addXP(xpDelta);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: task.isCompleted
                                  ? AppColors.success
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: task.isCompleted
                                    ? AppColors.success
                                    : cs.outlineVariant,
                                width: 2,
                              ),
                            ),
                            child: task.isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Category icon
                        Icon(
                          categoryIcon,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        // Task title
                        Expanded(
                          child: Text(
                            task.title,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? cs.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DifficultyChip(
                          difficulty: task.difficulty,
                          showXP: true,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Health':
        return Icons.favorite_rounded;
      case 'Fitness':
        return Icons.fitness_center_rounded;
      case 'Learning':
        return Icons.school_rounded;
      case 'Work':
        return Icons.work_rounded;
      case 'Social':
        return Icons.people_rounded;
      case 'Creative':
        return Icons.palette_rounded;
      case 'Mindfulness':
        return Icons.self_improvement_rounded;
      case 'Chores':
        return Icons.home_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }
}
