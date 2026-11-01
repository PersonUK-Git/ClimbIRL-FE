import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/task/task_cubit.dart';
import '../../../cubits/profile/profile_cubit.dart';
import '../../../cubits/profile/profile_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/task_model.dart';
import '../../../widgets/climb_ui.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  String _selectedCategory = AppConstants.taskCategories.first;
  String _selectedDifficulty = 'Easy';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New task', style: tt.headlineLarge),
          const SizedBox(height: 18),

          // Title input
          TextField(
            controller: _titleController,
            autofocus: true,
            style: tt.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'What do you want to accomplish?',
            ),
          ),

          const SizedBox(height: 22),

          // Category
          Text('Category', style: tt.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.taskCategories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.onSurface : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    category,
                    style: tt.labelMedium?.copyWith(
                      color: isSelected ? cs.surface : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // Difficulty, each with the tokens the user has left
          Text('Difficulty', style: tt.titleSmall),
          const SizedBox(height: 10),
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              final tokens = profileState.user.tokens;
              final difficulties = AppConstants.difficulties;
              return Row(
                children: List.generate(difficulties.length, (index) {
                  final difficulty = difficulties[index];
                  final isSelected = _selectedDifficulty == difficulty;
                  final count = tokens[difficulty.toLowerCase()] ?? 0;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDifficulty = difficulty),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? cs.onSurface : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            DifficultyDots(difficulty: difficulty, dotSize: 6),
                            const SizedBox(height: 10),
                            Text(difficulty, style: tt.labelMedium?.copyWith(color: cs.onSurface)),
                            const SizedBox(height: 2),
                            Text(
                              '$count left',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          const SizedBox(height: 24),

          // Add button
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              final tokens = profileState.user.tokens;
              final tokenKey = _selectedDifficulty.toLowerCase();
              final hasToken = (tokens[tokenKey] ?? 0) > 0;

              return SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: hasToken ? _addTask : null,
                  child: Text(
                    hasToken
                        ? 'Add task  ·  +${AppColors.difficultyXP(_selectedDifficulty)} XP'
                        : 'No $_selectedDifficulty tokens',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _addTask() async {
    if (_titleController.text.trim().isEmpty) return;

    final profileCubit = context.read<ProfileCubit>();
    final tokens = profileCubit.state.user.tokens;
    final tokenKey = _selectedDifficulty.toLowerCase();

    if ((tokens[tokenKey] ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You do not have enough $_selectedDifficulty tokens!'),
        ),
      );
      return;
    }

    final task = TaskModel(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      xpReward: AppColors.difficultyXP(_selectedDifficulty),
      createdAt: DateTime.now(),
      dueDate: DateTime.now(),
    );

    try {
      final updatedUser = await context.read<TaskCubit>().addTask(task);
      if (updatedUser != null) {
        profileCubit.updateFromUser(updatedUser);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create task: ${e.toString()}'),
          ),
        );
      }
    }
  }
}
