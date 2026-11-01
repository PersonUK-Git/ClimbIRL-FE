import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/task/task_cubit.dart';
import '../../../cubits/task/task_state.dart';
import '../../../widgets/climb_ui.dart';
import '../../tasks/widgets/task_row.dart';

class TodayTasksSection extends StatelessWidget {
  final VoidCallback onCompleted;
  const TodayTasksSection({super.key, required this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final tasks = state.todayTasks;

        return AppCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                child: Row(
                  children: [
                    Expanded(child: Text("Today's tasks", style: tt.titleMedium)),
                    MutedLabel('${state.todayCompletedCount} of ${state.todayTotalCount}'),
                  ],
                ),
              ),
              if (tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                  child: Text(
                    'No tasks for today',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                )
              else
                ...tasks.map(
                  (task) => TaskRow(
                    key: ValueKey(task.id),
                    task: task,
                    onCompleted: onCompleted,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
