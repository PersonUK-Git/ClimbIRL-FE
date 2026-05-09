import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/task/task_cubit.dart';
import '../../../cubits/profile/profile_cubit.dart';
import '../../../cubits/profile/profile_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/task_model.dart';

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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Token display
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              final tokens = profileState.user.tokens;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTokenHeaderItem('Easy', tokens['easy'] ?? 0, 'assets/token_easy.png'),
                  _buildTokenHeaderItem('Medium', tokens['medium'] ?? 0, 'assets/token_medium.png'),
                  _buildTokenHeaderItem('Hard', tokens['hard'] ?? 0, 'assets/token_hard.png'),
                  _buildTokenHeaderItem('Epic', tokens['epic'] ?? 0, 'assets/token_epic.png'),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'New Task',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          // Title input
          TextField(
            controller: _titleController,
            autofocus: true,
            style: tt.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'What do you want to accomplish?',
              prefixIcon: Icon(Icons.edit_rounded),
            ),
          ),

          const SizedBox(height: 20),

          // Category
          Text(
            'Category',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.taskCategories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withValues(alpha: 0.12)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    category,
                    style: tt.labelMedium?.copyWith(
                      color: isSelected ? cs.primary : cs.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Difficulty
          Text(
            'Difficulty',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              final tokens = profileState.user.tokens;
              return Row(
                children: AppConstants.difficulties.map((difficulty) {
                  final isSelected = _selectedDifficulty == difficulty;
                  final color = AppColors.difficultyColor(difficulty);
                  final xp = AppColors.difficultyXP(difficulty);
                  
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDifficulty = difficulty),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.12)
                              : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : cs.outlineVariant.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              difficulty,
                              style: tt.labelMedium?.copyWith(
                                color: isSelected ? color : cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${xp}XP',
                              style: tt.labelSmall?.copyWith(
                                color: isSelected
                                    ? color.withValues(alpha: 0.7)
                                    : cs.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                height: 52,
                child: FilledButton(
                  onPressed: hasToken ? _addTask : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    hasToken
                        ? 'Add Task  ·  +${AppColors.difficultyXP(_selectedDifficulty)}XP'
                        : 'No $_selectedDifficulty Tokens',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildTokenHeaderItem(String type, int count, String assetPath) {
    return Column(
      children: [
        Image.asset(assetPath, width: 32, height: 32),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          '$type Token',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
