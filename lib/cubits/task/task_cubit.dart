import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/mock/mock_tasks.dart';
import '../../models/task_model.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  TaskCubit() : super(TaskState(tasks: List.from(mockTasks)));

  void setFilter(TaskFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  /// Toggle task completion. Returns the XP earned (positive) or lost (negative).
  int toggleTask(String taskId) {
    final tasks = state.tasks.map((task) {
      if (task.id == taskId) {
        final newCompleted = !task.isCompleted;
        return task.copyWith(
          isCompleted: newCompleted,
          completedAt: newCompleted ? DateTime.now() : null,
        );
      }
      return task;
    }).toList();

    final task = state.tasks.firstWhere((t) => t.id == taskId);
    final xpDelta = task.isCompleted ? -task.xpReward : task.xpReward;

    emit(state.copyWith(tasks: tasks));
    return xpDelta;
  }

  void addTask(TaskModel task) {
    final tasks = [...state.tasks, task];
    emit(state.copyWith(tasks: tasks));
  }

  void removeTask(String taskId) {
    final tasks = state.tasks.where((t) => t.id != taskId).toList();
    emit(state.copyWith(tasks: tasks));
  }
}
