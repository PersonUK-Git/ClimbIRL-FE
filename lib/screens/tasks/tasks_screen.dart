import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';

import '../../cubits/task/task_cubit.dart';
import '../../cubits/task/task_state.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../cubits/profile/profile_state.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../widgets/climb_ui.dart';
import 'widgets/add_task_sheet.dart';
import 'widgets/task_card_skeleton.dart';
import 'widgets/task_row.dart';
import '../../core/ads/ad_manager.dart';
import 'widgets/milestone_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _celebrate() {
    _confettiController.play();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        return SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, profileState) {
                      final rerolls = profileState.user.rerollsRemaining;
                      return ScreenHeader(
                        subtitle:
                            '${state.todayCompletedCount} of ${state.todayTotalCount} today  ·  '
                            '${rerolls > 0 ? '$rerolls rerolls left' : 'Reroll with an ad'}',
                        title: 'Tasks',
                        trailing: IconButton.filled(
                          tooltip: 'Add task',
                          onPressed: () => _showAddTaskSheet(context),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Filter Tabs
                  PillTabs(
                    labels: TaskFilter.values
                        .map((f) => f.name[0].toUpperCase() + f.name.substring(1))
                        .toList(),
                    selectedIndex: state.filter.index,
                    onSelected: (index) => context
                        .read<TaskCubit>()
                        .setFilter(TaskFilter.values[index]),
                  ),

                  // Milestone Section
                  BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, profileState) {
                      return MilestoneCard(
                        user: profileState.user,
                        milestones: profileState.milestones,
                        onWatchAd: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Loading Ad...'), duration: Duration(seconds: 1)),
                          );

                          final success = await AdManager.instance.showRewardedAd(
                            onRewardEarned: () async {
                              final profileCubit = context.read<ProfileCubit>();
                              final reward = await profileCubit.recordMilestoneAd();
                              if (reward != null && context.mounted) {
                                _showRewardModal(context, reward);
                              }
                            },
                          );

                          if (!success) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ad failed to load. Please try again.')),
                            );
                          }
                        },
                      );
                    },
                  ),

                  // Task List
                  Expanded(
                    child: state.status == TaskStatus.loading ||
                            state.status == TaskStatus.initial
                        ? ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                            itemCount: 5,
                            itemBuilder: (context, index) => const TaskCardSkeleton(),
                          )
                        : state.filteredTasks.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Nothing here yet', style: tt.headlineSmall),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tap + to add a new task',
                                      style: tt.bodyMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 80),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                                itemCount: state.filteredTasks.length,
                                itemBuilder: (context, index) {
                                  final task = state.filteredTasks[index];
                                  return _TaskCard(
                                    task: task,
                                    onCompleted: _celebrate,
                                  );
                                },
                              ),
                  ),
                ],
              ),
              // Confetti overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 14,
                  gravity: 0.1,
                  colors: AppColors.confetti,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRewardModal(BuildContext context, String rewardType) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TokenMark(difficulty: rewardType, size: 84),
              const SizedBox(height: 20),
              Text('Token earned', style: tt.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'You earned ${rewardType == 'easy' || rewardType == 'epic' ? 'an' : 'a'} '
                '$rewardType token. Keep watching ads to earn more.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Claim token'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<TaskCubit>()),
          BlocProvider.value(value: context.read<ProfileCubit>()),
        ],
        child: const AddTaskSheet(),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onCompleted;

  const _TaskCard({
    required this.task,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dismissible(
      key: Key(task.id),
      direction: task.isCompleted ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 22),
        alignment: Alignment.centerRight,
        child: Text('Delete', style: tt.labelLarge?.copyWith(color: cs.error)),
      ),
      onDismissed: (_) {
        context.read<TaskCubit>().removeTask(task.id);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: cs.surface,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(22),
          child: TaskRow(
            task: task,
            onCompleted: onCompleted,
            trailing: task.isCompleted
                ? null
                : IconButton(
                    tooltip: 'Reroll task',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () => _reroll(context),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _reroll(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final taskCubit = context.read<TaskCubit>();
    final profileCubit = context.read<ProfileCubit>();
    final rerolls = profileCubit.state.user.rerollsRemaining;

    bool watchAd = rerolls <= 0;

    if (watchAd) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No rerolls left'),
          content: const Text('Watch a rewarded ad to reroll this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Watch ad'),
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
      // Force a full tasks reload to ensure everything is in sync
      await taskCubit.loadTasks();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task rerolled successfully!')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reroll task')),
        );
      }
    }
  }
}
