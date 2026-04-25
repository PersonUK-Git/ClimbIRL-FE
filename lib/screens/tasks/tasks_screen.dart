import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../cubits/task/task_cubit.dart';
import '../../cubits/task/task_state.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../cubits/leaderboard/leaderboard_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../widgets/difficulty_chip.dart';
import 'widgets/add_task_sheet.dart';
import 'widgets/task_card_skeleton.dart';
import 'package:flutter/services.dart';
import '../../cubits/profile/profile_state.dart';
import '../../core/ads/ad_manager.dart';


class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tasks',
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        BlocBuilder<ProfileCubit, ProfileState>(
                          builder: (context, profileState) {
                            final rerolls = profileState.user.rerollsRemaining;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 14,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rerolls > 0 ? 'Rerolls: $rerolls/2' : 'Watch Ad to Reroll',
                                    style: tt.labelSmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton.small(
                          heroTag: 'add_task',
                          onPressed: () => _showAddTaskSheet(context),
                          child: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: TaskFilter.values.map((filter) {
                      final isSelected = state.filter == filter;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              context.read<TaskCubit>().setFilter(filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).cardTheme.color
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: cs.shadow.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                filter.name[0].toUpperCase() +
                                    filter.name.substring(1),
                                style: tt.labelMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? cs.onSurface
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Task List
              Expanded(
                child: state.status == TaskStatus.loading ||
                        state.status == TaskStatus.initial
                    ? ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: 5,
                        itemBuilder: (context, index) =>
                            const TaskCardSkeleton().animate().fadeIn(
                                  delay: Duration(milliseconds: 100 * index),
                                ),
                      )
                    : state.filteredTasks.isEmpty
                        ? Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 64,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No tasks here',
                              style: tt.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + to add a new task',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: state.filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = state.filteredTasks[index];
                          return _TaskCard(task: task)
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 50 * index),
                                duration: 400.ms,
                              )
                              .slideX(
                                begin: 0.05,
                                end: 0,
                                delay: Duration(milliseconds: 50 * index),
                                duration: 400.ms,
                                curve: Curves.easeOut,
                              );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<TaskCubit>(),
        child: const AddTaskSheet(),
      ),
    );
  }
}
class _TaskCard extends StatelessWidget {
  final TaskModel task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dismissible(
      key: Key(task.id),
      direction: task.isCompleted ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      onDismissed: (_) {
        context.read<TaskCubit>().removeTask(task.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
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
              onTap: () async {
                final taskCubit = context.read<TaskCubit>();
                final profileCubit = context.read<ProfileCubit>();
                
                final updatedUser = await taskCubit.toggleTask(task.id);
                if (updatedUser != null) {
                  profileCubit.updateFromUser(updatedUser);
                  // Refresh leaderboard to reflect new XP/Rank
                  if (context.mounted) {
                    context.read<LeaderboardCubit>().loadLeaderboard();
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
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
                        size: 18,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted
                          ? cs.onSurfaceVariant
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(task.category),
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.category,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            DifficultyChip(difficulty: task.difficulty),
            if (!task.isCompleted) ...[
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: cs.primary.withValues(alpha: 0.7),
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final taskCubit = context.read<TaskCubit>();
                  final profileCubit = context.read<ProfileCubit>();
                  final rerolls = profileCubit.state.user.rerollsRemaining;

                  bool watchAd = rerolls <= 0;

                  if (watchAd) {
                    final proceed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('No Rerolls Left'),
                        content: const Text('Watch a rewarded ad to reroll this task?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Watch Ad'),
                          ),
                        ],
                      ),
                    );

                    if (proceed != true) return;

                    // Show loading
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Loading Ad...'), duration: Duration(seconds: 1)),
                    );

                    final success = await AdManager.instance.showRewardedAd(
                      onRewardEarned: () {}, // Success tracked by backend
                    );

                    if (!success) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ad failed to load. Please try again.')),
                      );
                      return;
                    }
                  }

                  final updatedUser = await taskCubit.rerollTask(task.id, watchAd: watchAd);
                  if (updatedUser != null) {
                    profileCubit.updateFromUser(updatedUser);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to reroll task'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
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
