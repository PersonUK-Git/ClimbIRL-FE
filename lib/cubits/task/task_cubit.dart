import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/api_repository.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final ApiRepository repository;

  TaskCubit({required this.repository}) : super(const TaskState());

  Future<void> loadTasks() async {
    final tasks = await repository.getTasks();
    emit(state.copyWith(tasks: tasks));
  }

  void setFilter(TaskFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  /// Toggle task completion. Returns the updated User model if successful.
  Future<UserModel?> toggleTask(String taskId) async {
    // Optimistic UI update
    final originalTasks = List<TaskModel>.from(state.tasks);
    final updatedTasks = state.tasks.map((t) {
      if (t.id == taskId) {
        final newCompleted = !t.isCompleted;
        return t.copyWith(
          isCompleted: newCompleted,
          completedAt: newCompleted ? DateTime.now() : null,
        );
      }
      return t;
    }).toList();
    emit(state.copyWith(tasks: updatedTasks));

    // Call backend
    final updatedUser = await repository.completeTask(taskId);
    if (updatedUser == null) {
      // Revert if failed
      emit(state.copyWith(tasks: originalTasks));
      return null;
    }

    return updatedUser;
  }

  Future<void> addTask(TaskModel task) async {
    final newTask = await repository.createTask(task);
    if (newTask != null) {
      final tasks = [...state.tasks, newTask];
      emit(state.copyWith(tasks: tasks));
    }
  }

  Future<void> removeTask(String taskId) async {
    final success = await repository.deleteTask(taskId);
    if (success) {
      final tasks = state.tasks.where((t) => t.id != taskId).toList();
      emit(state.copyWith(tasks: tasks));
    }
  }
}
