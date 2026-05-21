import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../cubits/onboarding/onboarding_cubit.dart';
import '../../core/network/api_constants.dart';
import '../../data/repositories/api_repository.dart';

import '../../cubits/profile/profile_cubit.dart';
import '../../models/user_model.dart';
import '../login/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Profile Picture',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({required IconData icon, required String label, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primaryContainer,
              child: Icon(icon, color: cs.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
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

  final List<OnboardingSlide> _introSlides = [
    const OnboardingSlide(
      title: 'Gamify Your Life',
      description: 'Turn your daily chores and habits into a rewarding RPG experience. Every task is a quest.',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF6366F1),
    ),
    const OnboardingSlide(
      title: 'Level Up with Tasks',
      description: 'Complete tasks to earn XP and level up your profile. Custom categories keep you organized.',
      icon: Icons.task_alt_rounded,
      color: Color(0xFF10B981),
    ),
    const OnboardingSlide(
      title: 'Join the Race',
      description: 'Compete with friends and the community on the global leaderboard. Who will reach the top?',
      icon: Icons.leaderboard_rounded,
      color: Color(0xFFF59E0B),
    ),
    const OnboardingSlide(
      title: 'Ready to Climb?',
      description: 'Your journey starts now. Take the first step and master your daily routine.',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFEC4899),
    ),
  ];

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
            backgroundColor: Colors.redAccent,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalPages = _introSlides.length + 3; // 4 intro + 3 profile
    final isLastPage = _currentPage == totalPages - 1;
    final currentColor = _currentPage < 4 
        ? _introSlides[_currentPage].color 
        : cs.primary;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Background Gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    currentColor.withValues(alpha: 0.15),
                    cs.surface,
                  ],
                ),
              ),
            ),
  
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                FocusScope.of(context).unfocus();
                setState(() => _currentPage = index);
              },
              children: [
                ..._introSlides.map((slide) => _buildIntroSlide(slide, cs)),
                _buildIdentitySlide(cs),
                _buildContactSlide(cs),
                _buildHandleSlide(cs),
              ],
            ),

          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              children: [
                // Page Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalPages,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? currentColor
                            : cs.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_currentPage == 3) ...[
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: currentColor,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: currentColor.withValues(alpha: 0.5),
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchURL(ApiConstants.privacyPolicy),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            color: currentColor,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: currentColor.withValues(alpha: 0.5),
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchURL(ApiConstants.termsOfService),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                ],
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isNavEnabled() ? () {
                      if (isLastPage) {
                        _handleComplete();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isLastPage ? 'Get Started' : 'Continue',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (_currentPage < 4) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              color: currentColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: currentColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSlide(OnboardingSlide slide, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 100,
              color: slide.color,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 48),
          Text(
            slide.title,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            slide.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildIdentitySlide(ColorScheme cs) {
    return _buildFormSlide(
      cs,
      title: 'Who are you?',
      subtitle: 'Let\'s start with the basics.',
      children: [
        GestureDetector(
          onTap: _pickAvatar,
          child: Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: _avatarImage != null ? FileImage(_avatarImage!) : null,
                  child: _avatarImage == null
                      ? Icon(Icons.person_rounded, size: 50, color: cs.primary)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primary,
                    child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField(cs, 'Full Name', _nameController, Icons.badge_outlined),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(cs, 'Gender', ['Male', 'Female', 'Other'], (val) {
                setState(() => _selectedGender = val);
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePicker(cs),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactSlide(ColorScheme cs) {
    return _buildFormSlide(
      cs,
      title: 'Stay Connected',
      subtitle: 'Your email helps us keep your progress safe.',
      children: [
        _buildTextField(cs, 'Email Address', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildHandleSlide(ColorScheme cs) {
    return _buildFormSlide(
      cs,
      title: 'Pick a Handle',
      subtitle: 'This is how other climbers will see you.',
      children: [
        TextField(
          controller: _usernameController,
          onChanged: _onUsernameChanged,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixIcon: const Icon(Icons.alternate_email_rounded),
            suffixIcon: _isCheckingUsername
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_isUsernameAvailable != null
                    ? Icon(
                        _isUsernameAvailable!
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: _isUsernameAvailable! ? Colors.green : Colors.red,
                      )
                    : null),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            helperText: _isUsernameAvailable == true ? 'Username is available! ' : null,
            helperStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            errorText: _isUsernameAvailable == false ? 'Username is already taken' : null,
          ),
        ),
      ],
    );
  }
  Widget _buildFormSlide(ColorScheme cs, {required String title, required String subtitle, required List<Widget> children}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ).animate().fadeIn().slideX(begin: -0.1, end: 0),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 40),
            ...children,
            const SizedBox(height: 120), // Extra space for keyboard and bottom controls
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(ColorScheme cs, String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildDropdown(ColorScheme cs, String label, List<String> options, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker(ColorScheme cs) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              _selectedDate == null ? 'DOB' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(color: _selectedDate == null ? cs.onSurfaceVariant : cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
