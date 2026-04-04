import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../cubits/onboarding/onboarding_cubit.dart';

import '../../cubits/profile/profile_cubit.dart';

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
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    final profileCubit = context.read<ProfileCubit>();
    final onboardingCubit = context.read<OnboardingCubit>();

    final updatedUser = profileCubit.state.user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      gender: _selectedGender,
      dateOfBirth: _selectedDate,
    );

    profileCubit.updateUser(updatedUser);
    onboardingCubit.completeOnboarding();
  }

  bool _isNavEnabled() {
    if (_currentPage < 4) return true;
    if (_currentPage == 4) {
      return _nameController.text.isNotEmpty &&
          _selectedGender != null &&
          _selectedDate != null;
    }
    if (_currentPage == 5) return _emailController.text.contains('@');
    if (_currentPage == 6) return _usernameController.text.length >= 3;
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
      body: Stack(
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
            onPageChanged: (index) => setState(() => _currentPage = index),
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
              ],
            ),
          ),
        ],
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
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.person_rounded, size: 50, color: cs.primary),
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
        _buildTextField(cs, 'Username', _usernameController, Icons.alternate_email_rounded),
      ],
    );
  }

  Widget _buildFormSlide(ColorScheme cs, {required String title, required String subtitle, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
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
        ],
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
