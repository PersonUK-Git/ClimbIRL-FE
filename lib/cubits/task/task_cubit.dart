import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/api_repository.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final ApiRepository repository;

  TaskCubit({required this.repository}) : super(const TaskState());

  Future<void> loadTasks({bool silent = false}) async {
    if (!silent || state.status != TaskStatus.success) {
      emit(state.copyWith(status: TaskStatus.loading));
    }
    try {
      final tasks = await repository.getTasks();
      emit(state.copyWith(tasks: tasks, status: TaskStatus.success));
    } catch (e) {
      if (!silent) {
        emit(state.copyWith(status: TaskStatus.failure, errorMessage: e.toString()));
      }
    }
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

  /// Verify task with AI proof. Returns the updated User model if successful.
  Future<UserModel?> verifyTask({
    required String taskId,
    String? imageBase64,
    String? proofNote,
  }) async {
    try {
      final result = await repository.verifyTask(
        taskId: taskId,
        imageBase64: imageBase64,
        proofNote: proofNote,
      );

      if (result != null) {
        final updatedTask = result['task'] as TaskModel;
        final updatedUser = result['user'] as UserModel;

        final updatedTasks = state.tasks.map((t) => t.id == taskId ? updatedTask : t).toList();
        emit(state.copyWith(tasks: updatedTasks));
        return updatedUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> addTask(TaskModel task) async {
    try {
      final result = await repository.createTask(task);
      if (result != null) {
        final updatedTask = result['task'] as TaskModel;
        final updatedUser = result['user'] as UserModel;

        final tasks = [...state.tasks, updatedTask];
        emit(state.copyWith(tasks: tasks));
        return updatedUser;
      }
      return null;
    } catch (e) {
      emit(state.copyWith(status: TaskStatus.failure, errorMessage: e.toString()));
      rethrow;
    }
  }

  Future<UserModel?> rerollTask(String taskId, {bool watchAd = false}) async {
    print('[Reroll] Starting reroll for task: $taskId (watchAd: $watchAd)');
    emit(state.copyWith(status: TaskStatus.loading));
    try {
      final result = await repository.rerollTask(taskId, watchAd: watchAd);
      if (result != null) {
        print('[Reroll] Backend success. Reloading all tasks...');
        final updatedUser = result['user'] as UserModel;
        final tasks = await repository.getTasks();
        print('[Reroll] Fetched ${tasks.length} tasks. New titles: ${tasks.map((t) => t.title).toList()}');
        emit(state.copyWith(tasks: tasks, status: TaskStatus.success));
        return updatedUser;
      }
      print('[Reroll] Backend returned null result');
      emit(state.copyWith(status: TaskStatus.success));
      return null;
    } catch (e) {
      print('[Reroll] Error: $e');
      emit(state.copyWith(status: TaskStatus.failure, errorMessage: e.toString()));
      return null;
    }
  }

  Future<void> removeTask(String taskId) async {
    final task = state.tasks.firstWhere((t) => t.id == taskId);
    if (task.isCompleted) return;

    final success = await repository.deleteTask(taskId);
    if (success) {
      final tasks = state.tasks.where((t) => t.id != taskId).toList();
      emit(state.copyWith(tasks: tasks));
    }
  }
}
