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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

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
      } else if (mounted) {
        setState(() {
          _isVerifying = false;
          _error = "We couldn't verify this. Please try again.";
        });
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
        left: 20,
        right: 20,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('Show your work', style: tt.headlineLarge),
            const SizedBox(height: 6),
            Text(
              widget.task.title,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 22),

            // Photo Preview / Picker
            GestureDetector(
              onTap: _isVerifying ? null : _takePhoto,
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined, size: 28, color: cs.onSurface),
                          const SizedBox(height: 8),
                          Text('Take a proof photo', style: tt.labelLarge),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Note Field
            TextField(
              controller: _noteController,
              enabled: !_isVerifying,
              decoration: const InputDecoration(
                hintText: 'Add a note (optional)',
              ),
              maxLines: 2,
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: tt.bodySmall?.copyWith(color: cs.error),
              ).animate().fadeIn(duration: 200.ms),
            ],

            const SizedBox(height: 22),

            // Submit Button
            FilledButton(
              onPressed: _isVerifying ? null : _submit,
              child: _isVerifying
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onSurfaceVariant,
                      ),
                    )
                  : const Text('Verify and claim XP'),
            ),

            if (_isVerifying) ...[
              const SizedBox(height: 12),
              Text(
                'Checking your proof. This can take a moment.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
