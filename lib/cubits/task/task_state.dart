import 'package:equatable/equatable.dart';
import '../../models/task_model.dart';

enum TaskFilter { all, today, completed }
enum TaskStatus { initial, loading, success, failure }

class TaskState extends Equatable {
  final List<TaskModel> tasks;
  final TaskFilter filter;
  final TaskStatus status;
  final String? errorMessage;

  const TaskState({
    this.tasks = const [],
    this.filter = TaskFilter.all,
    this.status = TaskStatus.initial,
    this.errorMessage,
  });

  List<TaskModel> get filteredTasks {
    switch (filter) {
      case TaskFilter.today:
        final now = DateTime.now();
        return tasks.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.year == now.year &&
              t.dueDate!.month == now.month &&
              t.dueDate!.day == now.day;
        }).toList();
      case TaskFilter.completed:
        return tasks.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
        return tasks;
    }
  }

  List<TaskModel> get todayTasks {
    final now = DateTime.now();
    return tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList();
  }

  int get todayCompletedCount => todayTasks.where((t) => t.isCompleted).length;
  int get todayTotalCount => todayTasks.length;
  int get todayXPEarned =>
      todayTasks.where((t) => t.isCompleted).fold(0, (sum, t) => sum + t.xpReward);

  TaskState copyWith({
    List<TaskModel>? tasks,
    TaskFilter? filter,
    TaskStatus? status,
    String? errorMessage,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [tasks, filter, status, errorMessage];
}

