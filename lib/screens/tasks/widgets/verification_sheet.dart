import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/task_model.dart';
import '../../../cubits/task/task_cubit.dart';
import '../../../cubits/profile/profile_cubit.dart';
import '../../../cubits/leaderboard/leaderboard_cubit.dart';
import '../../../core/theme/app_colors.dart';

class VerificationSheet extends StatefulWidget {
  final TaskModel task;

  const VerificationSheet({super.key, required this.task});

  @override
  State<VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<VerificationSheet> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  final TextEditingController _noteController = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 1024,
    );

    if (photo != null) {
      setState(() {
        _image = File(photo.path);
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_image == null && _noteController.text.trim().isEmpty) {
      setState(() => _error = "Please provide a photo or a note as proof.");
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      String? base64Image;
      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      final taskCubit = context.read<TaskCubit>();
      final profileCubit = context.read<ProfileCubit>();

      final updatedUser = await taskCubit.verifyTask(
        taskId: widget.task.id,
        imageBase64: base64Image,
        proofNote: _noteController.text.trim(),
      );

      if (updatedUser != null) {
        profileCubit.updateFromUser(updatedUser);
        context.read<LeaderboardCubit>().loadLeaderboard();
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _error = e.toString().replaceAll("Exception:", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Verify Completion',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.task.title,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Photo Preview / Picker
          GestureDetector(
            onTap: _isVerifying ? null : _takePhoto,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _image != null ? AppColors.success : cs.outlineVariant,
                  width: 2,
                ),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 40, color: cs.primary),
                        const SizedBox(height: 8),
                        Text(
                          'Take Proof Photo',
                          style: tt.labelLarge?.copyWith(color: cs.primary),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Note Field
          TextField(
            controller: _noteController,
            enabled: !_isVerifying,
            decoration: InputDecoration(
              hintText: 'Add a note (optional)...',
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.edit_note_rounded),
            ),
            maxLines: 2,
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: tt.bodySmall?.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ).animate().shake(),
          ],

          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton(
            onPressed: _isVerifying ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Verify & Claim XP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
          
          if (_isVerifying) ...[
             const SizedBox(height: 16),
             Text(
               'Please wait while we verify your work...',
               style: tt.labelMedium?.copyWith(
                 color: cs.primary,
                 fontStyle: FontStyle.italic
               ),
               textAlign: TextAlign.center,
             ).animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 500.ms)
              .then()
              .fadeOut(duration: 500.ms),
          ],
        ],
      ),
    );
  }
}
