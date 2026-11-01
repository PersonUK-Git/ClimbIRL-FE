import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/leaderboard/leaderboard_cubit.dart';
import '../../../cubits/profile/profile_cubit.dart';
import '../../../cubits/task/task_cubit.dart';
import '../../../models/task_model.dart';
import '../../../widgets/difficulty_chip.dart';
import 'verification_sheet.dart';

/// Opens the proof sheet for a task and celebrates when it is completed.
Future<void> openTaskVerification(
  BuildContext context,
  TaskModel task,
  VoidCallback onCompleted,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<TaskCubit>()),
        BlocProvider.value(value: context.read<ProfileCubit>()),
        BlocProvider.value(value: context.read<LeaderboardCubit>()),
      ],
      child: VerificationSheet(task: task),
    ),
  );

  if (result == true) {
    onCompleted();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Great job! XP rewarded.')),
      );
    }
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Health':
      return Icons.favorite_border_rounded;
    case 'Fitness':
      return Icons.fitness_center_rounded;
    case 'Learning':
      return Icons.menu_book_rounded;
    case 'Work':
      return Icons.work_outline_rounded;
    case 'Social':
      return Icons.people_outline_rounded;
    case 'Creative':
      return Icons.palette_outlined;
    case 'Mindfulness':
      return Icons.self_improvement_rounded;
    case 'Chores':
      return Icons.home_outlined;
    default:
      return Icons.flag_outlined;
  }
}

/// One task: icon, title, difficulty on the left and its XP on the right.
class TaskRow extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onCompleted;
  final Widget? trailing;

  const TaskRow({
    super.key,
    required this.task,
    required this.onCompleted,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final done = task.isCompleted;

    return InkWell(
      onTap: done ? null : () => openTaskVerification(context, task, onCompleted),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check_rounded : categoryIcon(task.category),
                size: 21,
                color: done ? cs.onSurfaceVariant : cs.onSurface,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: tt.titleSmall?.copyWith(
                      fontSize: 15,
                      height: 1.25,
                      color: done ? cs.onSurfaceVariant : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  done
                      ? Text(
                          'Proof accepted',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        )
                      : DifficultyChip(difficulty: task.difficulty),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailing != null) trailing!,
            Text(
              '+${task.xpReward}',
              style: tt.titleSmall?.copyWith(
                fontSize: 15,
                color: done ? cs.onSurfaceVariant : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
