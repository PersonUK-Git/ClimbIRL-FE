import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_text_styles.dart';
import '../../cubits/onboarding/onboarding_cubit.dart';
import '../../core/network/api_constants.dart';
import '../../data/repositories/api_repository.dart';

import '../../cubits/profile/profile_cubit.dart';
import '../../models/user_model.dart';
import '../../widgets/dot_climb.dart';
import '../../widgets/climb_ui.dart';
import '../login/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;

  // Form State
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isLoading = false;

  // Image Picking State
  final ImagePicker _picker = ImagePicker();
  File? _avatarImage;
  String? _avatarBase64;

  // Username Availability State
  bool? _isUsernameAvailable;
  bool _isCheckingUsername = false;
  Timer? _usernameDebounce;

  void _onUsernameChanged(String value) {
    if (_usernameDebounce?.isActive ?? false) _usernameDebounce!.cancel();

    final trimmed = value.trim();
    if (trimmed.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await ApiRepository().isUsernameAvailable(trimmed);
      if (mounted) {
        setState(() {
          _isUsernameAvailable = available;
          _isCheckingUsername = false;
        });
      }
    });
  }

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 512,
      );

      if (image != null) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        setState(() {
          _avatarImage = file;
          _avatarBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    final profileCubit = context.read<ProfileCubit>();
    final onboardingCubit = context.read<OnboardingCubit>();

    setState(() => _isLoading = true);

    final updatedUser = UserModel(
      id: '', // Server will assign ID
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      gender: _selectedGender ?? '',
      dateOfBirth: _selectedDate,
    );

    final success = await profileCubit.register(updatedUser, avatarBase64: _avatarBase64);

    if (mounted) {
      if (success) {
        onboardingCubit.completeOnboarding();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Email or Username might be taken.'),
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  bool _isNavEnabled() {
    if (_currentPage < 4) return true;
    if (_currentPage == 4) {
      return _nameController.text.isNotEmpty &&
          _selectedGender != null &&
          _selectedDate != null;
    }
    if (_currentPage == 5) return _emailController.text.contains('@');
    if (_currentPage == 6) return _usernameController.text.length >= 3 && _isUsernameAvailable == true;
    return true;
  }

  void _nextPage() {
    if (_currentPage < 6) {
      setState(() {
        _currentPage++;
      });
    }
  }

  Widget _buildStepIndicator(int page) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
            height: 3,
            decoration: BoxDecoration(
              color: index <= page ? cs.onSurface : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        child: Text.rich(
          TextSpan(
            text: 'Already climbing? ',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            children: [
              TextSpan(
                text: 'Log in',
                style: tt.labelLarge?.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideContent({
    required Key key,
    required int pageIndex,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
    bool showTerms = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepIndicator(pageIndex),
        const SizedBox(height: 24),
        Text(title, style: tt.displayMedium),
        const SizedBox(height: 12),
        Text(
          description,
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        if (showTerms) ...[
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              children: [
                const TextSpan(text: 'By continuing you agree to our '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, decoration: TextDecoration.underline, decorationColor: cs.onSurfaceVariant),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _launchURL(ApiConstants.privacyPolicy),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, decoration: TextDecoration.underline, decorationColor: cs.onSurfaceVariant),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _launchURL(ApiConstants.termsOfService),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ),
        const SizedBox(height: 8),
        _buildLoginLink(),
      ],
    );
  }

  Widget _getCurrentGraphic() {
    switch (_currentPage) {
      case 0:
        return const _AscentGraphic(key: ValueKey(0), progress: 0.42);
      case 1:
        return const _TasksGraphic(key: ValueKey(1));
      case 2:
        return const _LeaderboardGraphic(key: ValueKey(2));
      case 3:
        return const _AscentGraphic(key: ValueKey(3), progress: 1.0);
      default:
        return const SizedBox(key: ValueKey(-1));
    }
  }

  Widget _getCurrentContent() {
    switch (_currentPage) {
      case 0:
        return _buildSlideContent(
          key: const ValueKey(0),
          pageIndex: 0,
          title: 'Your life.\nYour quest.',
          description: 'Turn daily habits into XP. Every task you finish makes you stronger.',
          buttonLabel: 'Get started',
          onPressed: _nextPage,
        );
      case 1:
        return _buildSlideContent(
          key: const ValueKey(1),
          pageIndex: 1,
          title: 'Do it.\nProve it.',
          description: 'Photo-verify your tasks to claim XP. No faking it. Every point is earned.',
          buttonLabel: 'Continue',
          onPressed: _nextPage,
        );
      case 2:
        return _buildSlideContent(
          key: const ValueKey(2),
          pageIndex: 2,
          title: 'Race your\nfriends.',
          description: "A weekly leaderboard shows who's actually putting in the work.",
          buttonLabel: 'Continue',
          onPressed: _nextPage,
        );
      case 3:
        return _buildSlideContent(
          key: const ValueKey(3),
          pageIndex: 3,
          title: 'Ready to\nclimb?',
          description: 'Your journey starts now.',
          buttonLabel: 'Create my account',
          onPressed: _nextPage,
          showTerms: true,
        );
      case 4:
        return _buildIdentityContent(key: const ValueKey(4));
      case 5:
        return _buildContactContent(key: const ValueKey(5));
      case 6:
        return _buildHandleContent(key: const ValueKey(6));
      default:
        return const SizedBox(key: ValueKey(-2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = 7;
    final isLastPage = _currentPage == totalPages - 1;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Graphic Section (only for page < 4)
                    if (_currentPage < 4) ...[
                      SizedBox(
                        height: 270,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _getCurrentGraphic(),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Content Section (Title, desc, steps, buttons, inputs)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: _getCurrentContent(),
                    ),

                    // Room for the bottom button when typing on form inputs
                    if (_currentPage >= 4) const SizedBox(height: 90),
                  ],
                ),
              ),
            ),

            // Top Left Back Navigation Button
            if (_currentPage > 0)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () {
                      setState(() {
                        _currentPage--;
                      });
                    },
                  ),
                ),
              ),

            // Bottom Controls (only for profile inputs)
            if (_currentPage >= 4)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: SafeArea(
                  top: false,
                  child: FilledButton(
                    onPressed: _isNavEnabled()
                        ? () {
                            if (isLastPage) {
                              _handleComplete();
                            } else {
                              _nextPage();
                            }
                          }
                        : null,
                    child: Text(isLastPage ? 'Get started' : 'Continue'),
                  ),
                ),
              ),

            if (_isLoading)
              ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader(String title, String description) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tt.displaySmall),
        const SizedBox(height: 8),
        Text(
          description,
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildIdentityContent({required Key key}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormHeader('Who are you?', "Let's start with the basics."),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _pickAvatar,
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: cs.surfaceContainerHighest,
                backgroundImage: _avatarImage != null ? FileImage(_avatarImage!) : null,
                child: _avatarImage == null
                    ? Icon(Icons.person_outline_rounded, size: 32, color: cs.onSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                _avatarImage == null ? 'Add a photo' : 'Change photo',
                style: tt.labelLarge?.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField('Full name', _nameController),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildDropdown('Gender', ['Male', 'Female', 'Other'], (val) {
                setState(() => _selectedGender = val);
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDatePicker(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactContent({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormHeader(
          'Stay connected.',
          'Your email helps us keep your progress safe.',
        ),
        _buildTextField('Email address', _emailController, keyboardType: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildHandleContent({required Key key}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormHeader(
          'Pick a handle.',
          'This is how other climbers will see you.',
        ),
        TextField(
          controller: _usernameController,
          onChanged: _onUsernameChanged,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixText: '@',
            suffixIcon: _isCheckingUsername
                ? const Padding(
                    padding: EdgeInsets.all(14.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_isUsernameAvailable != null
                    ? Icon(
                        _isUsernameAvailable!
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: _isUsernameAvailable! ? cs.primary : cs.error,
                      )
                    : null),
            helperText: _isUsernameAvailable == true ? 'Username is available' : null,
            helperStyle: tt.bodySmall?.copyWith(color: cs.primary),
            errorText: _isUsernameAvailable == false ? 'Username is already taken' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildDropdown(String label, List<String> options, Function(String?) onChanged) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      dropdownColor: cs.surface,
      decoration: InputDecoration(labelText: label),
      items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: InputDecorator(
        isEmpty: _selectedDate == null,
        decoration: const InputDecoration(labelText: 'Birth date'),
        child: Text(
          _selectedDate == null
              ? ''
              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

// Graphics for the intro slides
class _AscentGraphic extends StatelessWidget {
  final double progress;

  const _AscentGraphic({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: DotClimb(
        progress: progress,
        height: 190,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }
}

class _TasksGraphic extends StatelessWidget {
  const _TasksGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: AppCard(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PreviewTask('Morning workout', 'Hard', 100, true),
            _PreviewTask('Drink 2L water', 'Easy', 25, true),
            _PreviewTask('Read 30 minutes', 'Medium', 50, false),
            _PreviewTask('Study session', 'Medium', 50, false),
          ],
        ),
      ),
    );
  }
}

class _PreviewTask extends StatelessWidget {
  final String title;
  final String difficulty;
  final int xp;
  final bool completed;

  const _PreviewTask(this.title, this.difficulty, this.xp, this.completed);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: completed
                ? Icon(Icons.check_rounded, color: cs.onSurfaceVariant, size: 20)
                : Center(child: DifficultyDots(difficulty: difficulty, dotSize: 4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: tt.titleSmall?.copyWith(
                color: completed ? cs.onSurfaceVariant : null,
              ),
            ),
          ),
          Text(
            '+$xp',
            style: tt.titleSmall?.copyWith(
              color: completed ? cs.onSurfaceVariant : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardGraphic extends StatelessWidget {
  const _LeaderboardGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: AppCard(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PreviewRank(1, 'Alex K.', '18 day streak', '4,200'),
            _PreviewRank(2, 'You', '12 day streak', '3,840', isMe: true),
            _PreviewRank(3, 'Priya R.', '9 day streak', '3,210'),
            _PreviewRank(4, 'Marcus R.', '5 day streak', '2,980'),
          ],
        ),
      ),
    );
  }
}

class _PreviewRank extends StatelessWidget {
  final int rank;
  final String name;
  final String streak;
  final String xp;
  final bool isMe;

  const _PreviewRank(this.rank, this.name, this.streak, this.xp, {this.isMe = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$rank',
              style: AppTextStyles.display(
                17,
                color: isMe ? cs.secondary : cs.onSurfaceVariant,
                height: 1,
              ),
            ),
          ),
          UserAvatar(name: name, url: '', size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: tt.titleSmall),
                MutedLabel(streak),
              ],
            ),
          ),
          Text('$xp XP', style: tt.titleSmall),
        ],
      ),
    );
  }
}
