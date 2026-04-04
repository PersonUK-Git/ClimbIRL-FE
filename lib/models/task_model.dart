import 'package:equatable/equatable.dart';

class TaskModel extends Equatable {
  final String id;
  final String title;
  final String category;
  final String difficulty; // Easy, Medium, Hard, Epic
  final int xpReward;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dueDate;

  const TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.dueDate,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? category,
    String? difficulty,
    int? xpReward,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? dueDate,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        difficulty,
        xpReward,
        isCompleted,
        createdAt,
        completedAt,
        dueDate,
      ];
}
