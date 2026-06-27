import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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

  void _nextPage() {
    if (_currentPage < 6) {
      setState(() {
        _currentPage++;
      });
    }
  }

  Widget _buildDotsIndicator(int page) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(
        4,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: page == index ? 24 : 8,
          height: 5,
          decoration: BoxDecoration(
            color: page == index ? const Color(0xFF8070FF) : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideTitle(String prefix, String highlight) {
    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: GoogleFonts.outfit(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.1,
        ),
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: highlight,
            style: const TextStyle(color: Color(0xFF8070FF)),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideDescription(String desc) {
    return Text(
      desc,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }

  Widget _buildButton({required String label, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF0D0B18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        child: RichText(
          text: const TextSpan(
            style: TextStyle(color: Colors.white54, fontSize: 14),
            children: [
              TextSpan(text: 'Already climbing? '),
              TextSpan(
                text: 'Log in',
                style: TextStyle(
                  color: Color(0xFF8070FF),
                  fontWeight: FontWeight.bold,
                ),
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
    required String titlePrefix,
    required String titleHighlight,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
    bool showTerms = false,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDotsIndicator(pageIndex),
        const SizedBox(height: 24),
        _buildSlideTitle(titlePrefix, titleHighlight),
        const SizedBox(height: 16),
        _buildSlideDescription(description),
        if (showTerms) ...[
          const SizedBox(height: 24),
          RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'By continuing you agree to our '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: Color(0xFF8070FF),
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _launchURL(ApiConstants.privacyPolicy),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Terms of Service',
                  style: const TextStyle(
                    color: Color(0xFF8070FF),
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _launchURL(ApiConstants.termsOfService),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        _buildButton(
          label: buttonLabel,
          onPressed: onPressed,
        ),
        const SizedBox(height: 16),
        _buildLoginLink(),
      ],
    );
  }

  Widget _getCurrentGraphic() {
    switch (_currentPage) {
      case 0:
        return const _OrbitingCardsGraphic(key: ValueKey(0));
      case 1:
        return const _TasksGraphic(key: ValueKey(1));
      case 2:
        return const _LeaderboardGraphic(key: ValueKey(2));
      case 3:
        return const _ClimbGraphic(key: ValueKey(3));
      default:
        return const SizedBox(key: ValueKey(-1));
    }
  }

  Widget _getCurrentContent(ColorScheme cs) {
    switch (_currentPage) {
      case 0:
        return _buildSlideContent(
          key: const ValueKey(0),
          pageIndex: 0,
          titlePrefix: 'Your life.\nYour ',
          titleHighlight: 'quest.',
          description: 'Turn daily habits into XP. Every task you finish makes you stronger.',
          buttonLabel: 'Get started',
          onPressed: _nextPage,
        );
      case 1:
        return _buildSlideContent(
          key: const ValueKey(1),
          pageIndex: 1,
          titlePrefix: 'Do it.\n',
          titleHighlight: 'Prove it.',
          description: 'Photo-verify your tasks to claim XP. No faking it — every point is earned.',
          buttonLabel: 'Continue',
          onPressed: _nextPage,
        );
      case 2:
        return _buildSlideContent(
          key: const ValueKey(2),
          pageIndex: 2,
          titlePrefix: 'Race your\n',
          titleHighlight: 'friends.',
          description: 'Weekly leaderboard. See who\'s actually putting in the work — and who isn\'t.',
          buttonLabel: 'Continue',
          onPressed: _nextPage,
        );
      case 3:
        return _buildSlideContent(
          key: const ValueKey(3),
          pageIndex: 3,
          titlePrefix: 'Ready to\n',
          titleHighlight: 'climb?',
          description: 'Your journey starts now.',
          buttonLabel: 'Create my account',
          onPressed: _nextPage,
          showTerms: true,
        );
      case 4:
        return _buildIdentityContent(cs, key: const ValueKey(4));
      case 5:
        return _buildContactContent(cs, key: const ValueKey(5));
      case 6:
        return _buildHandleContent(cs, key: const ValueKey(6));
      default:
        return const SizedBox(key: ValueKey(-2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalPages = 7;
    final isLastPage = _currentPage == totalPages - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF07050F),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.6),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1E173C),
                    Color(0xFF07050F),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Graphic Section (only for page < 4)
                      if (_currentPage < 4) ...[
                        AnimatedSize(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          child: SizedBox(
                            height: _currentPage == 3 ? 220 : 280,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              switchInCurve: Curves.easeInOut,
                              switchOutCurve: Curves.easeInOut,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: _getCurrentGraphic(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Content Section (Title, desc, dots, buttons, inputs)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: _getCurrentContent(cs),
                        ),
                      ),
                      
                      // Padding for bottom button when typing on form inputs
                      if (_currentPage >= 4) const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),

            // Top Left Back Navigation Button
            if (_currentPage > 0)
              Positioned(
                top: 20,
                left: 16,
                child: SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                      onPressed: () {
                        setState(() {
                          _currentPage--;
                        });
                      },
                    ),
                  ),
                ),
              ),

            // Bottom Controls (only for profile inputs)
            if (_currentPage >= 4)
              Positioned(
                bottom: 40,
                left: 32,
                right: 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isNavEnabled()
                            ? () {
                                if (isLastPage) {
                                  _handleComplete();
                                } else {
                                  _nextPage();
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8070FF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF8070FF).withValues(alpha: 0.4),
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isLastPage ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8070FF)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityContent(ColorScheme cs, {required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Who are you?',
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Let\'s start with the basics.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _pickAvatar,
          child: Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF131124),
                  backgroundImage: _avatarImage != null ? FileImage(_avatarImage!) : null,
                  child: _avatarImage == null
                      ? const Icon(Icons.person_rounded, size: 50, color: Colors.white54)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF8070FF),
                    child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField('Full Name', _nameController, Icons.badge_outlined),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdown('Gender', ['Male', 'Female', 'Other'], (val) {
                setState(() => _selectedGender = val);
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePicker(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactContent(ColorScheme cs, {required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Stay Connected',
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your email helps us keep your progress safe.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
        const SizedBox(height: 32),
        _buildTextField('Email Address', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildHandleContent(ColorScheme cs, {required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Pick a Handle',
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This is how other climbers will see you.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _usernameController,
          onChanged: _onUsernameChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Username',
            labelStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.white54),
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
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF8070FF)),
            ),
            filled: true,
            fillColor: const Color(0xFF131124),
            helperText: _isUsernameAvailable == true ? 'Username is available! ' : null,
            helperStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            errorText: _isUsernameAvailable == false ? 'Username is already taken' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF8070FF)),
        ),
        filled: true,
        fillColor: const Color(0xFF131124),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      dropdownColor: const Color(0xFF131124),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF8070FF)),
        ),
        filled: true,
        fillColor: const Color(0xFF131124),
      ),
      items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker() {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF131124),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.white54),
            const SizedBox(width: 8),
            Text(
              _selectedDate == null ? 'DOB' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(color: _selectedDate == null ? Colors.white54 : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Graphic widgets for high-fidelity animations
class _OrbitingCardsGraphic extends StatefulWidget {
  const _OrbitingCardsGraphic({super.key});

  @override
  State<_OrbitingCardsGraphic> createState() => _OrbitingCardsGraphicState();
}

class _OrbitingCardsGraphicState extends State<_OrbitingCardsGraphic> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * 2 * math.pi;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Concentric background circles
              ...List.generate(3, (index) {
                final radius = 55.0 + index * 30.0;
                return Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF8070FF).withValues(alpha: 0.05 + (index * 0.03)),
                      width: 1.5,
                    ),
                  ),
                );
              }),
              // Center Star Card
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF131124),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF8070FF).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8070FF).withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFF8070FF),
                  size: 44,
                ),
              ),
              // Orbiting Card 1: Level 8 (at angle + 0)
              _buildOrbitingCard(
                angle: angle,
                radius: 100,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131124),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.38), blurRadius: 10)],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Level 8',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '340 / 500 XP',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              // Orbiting Card 2: 12 streak (at angle + 2*pi/3)
              _buildOrbitingCard(
                angle: angle + (2 * math.pi / 3),
                radius: 95,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131124),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.38), blurRadius: 10)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.amber, size: 8),
                      SizedBox(width: 6),
                      Text(
                        '🔥 12 streak',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // Orbiting Card 3: +50 XP (at angle + 4*pi/3)
              _buildOrbitingCard(
                angle: angle + (4 * math.pi / 3),
                radius: 90,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131124),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.38), blurRadius: 10)],
                  ),
                  child: const Text(
                    '⚡ +50 XP',
                    style: TextStyle(color: Color(0xFF8070FF), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrbitingCard({
    required double angle,
    required double radius,
    required Widget child,
  }) {
    // We compute the X and Y coordinates on a slightly elliptical circle for better visual depth
    final double x = radius * 1.35 * math.cos(angle);
    final double y = radius * 0.85 * math.sin(angle);
    return Transform.translate(
      offset: Offset(x, y),
      child: child,
    );
  }
}

class _TasksGraphic extends StatefulWidget {
  const _TasksGraphic({super.key});

  @override
  State<_TasksGraphic> createState() => _TasksGraphicState();
}

class _TasksGraphicState extends State<_TasksGraphic> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0.4, end: 0.68).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Level Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131124),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF231E47),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.star_rounded, color: Color(0xFF8070FF), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Level 7 → 8',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '340 / 500 XP earned today',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      // Animated Progress Bar
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8070FF)),
                              minHeight: 6,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tasks Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131124),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                _buildTaskRow('Morning workout', '+50 XP', true),
                const Divider(color: Colors.white10, height: 20),
                _buildTaskRow('Drink 2L water', '+20 XP', true),
                const Divider(color: Colors.white10, height: 20),
                _buildTaskRow('Read 30 minutes', '+30 XP', false),
                const Divider(color: Colors.white10, height: 20),
                _buildTaskRow('Study session', '+60 XP', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(String title, String xp, bool completed) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: completed ? const Color(0xFF8070FF) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed ? const Color(0xFF8070FF) : Colors.white24,
              width: 2,
            ),
          ),
          child: completed ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: completed ? Colors.white38 : Colors.white,
              fontSize: 14,
              decoration: completed ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          xp,
          style: TextStyle(
            color: completed ? Colors.white38 : const Color(0xFF8070FF),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _LeaderboardGraphic extends StatelessWidget {
  const _LeaderboardGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131124),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'THIS WEEK',
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              Text(
                'Resets Monday',
                style: TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLeaderboardRow(1, 'Alex K.', '18 day streak', '4,200', '↑ +380 today', Colors.amber, 0),
          const SizedBox(height: 12),
          _buildLeaderboardRow(2, 'You', '12 day streak', '3,840', '↑ +340 today', const Color(0xFF8070FF), 1, isMe: true),
          const SizedBox(height: 12),
          _buildLeaderboardRow(3, 'Priya R.', '9 day streak', '3,210', '↑ +210 today', Colors.white70, 2),
          const SizedBox(height: 12),
          _buildLeaderboardRow(4, 'Marcus R.', '5 day streak', '2,980', '↓ -80 today', Colors.white38, 3, isDown: true),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(
    int rank,
    String name,
    String streak,
    String xp,
    String todayXp,
    Color rankColor,
    int delayIndex, {
    bool isMe = false,
    bool isDown = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '$rank',
            style: TextStyle(color: rankColor, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 18,
          backgroundColor: isMe ? const Color(0xFF231E47) : Colors.white10,
          child: Text(
            name.substring(0, 2),
            style: TextStyle(color: isMe ? const Color(0xFF8070FF) : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: isMe ? FontWeight.bold : FontWeight.w600),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF231E47),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('you', style: TextStyle(color: Color(0xFF8070FF), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '🔥 $streak',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              xp,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              todayXp,
              style: TextStyle(color: isDown ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: (delayIndex * 150).ms, duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
}

class _ClimbGraphic extends StatefulWidget {
  const _ClimbGraphic({super.key});

  @override
  State<_ClimbGraphic> createState() => _ClimbGraphicState();
}

class _ClimbGraphicState extends State<_ClimbGraphic> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _arrowAnimation = Tween<double>(begin: 30.0, end: -40.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric circles
          ...List.generate(3, (index) {
            final radius = 45.0 + index * 30.0;
            return Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8070FF).withValues(alpha: 0.05 + (index * 0.03)),
                  width: 1.5,
                ),
              ),
            );
          }),
          // Central dot
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF8070FF),
              shape: BoxShape.circle,
            ),
          ),
          // Animated rising arrow
          AnimatedBuilder(
            animation: _arrowAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _arrowAnimation.value),
                child: Opacity(
                  // Fade out as it reaches the top
                  opacity: ((_arrowAnimation.value + 40) / 70.0).clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF8070FF), size: 36),
                      SizedBox(
                        width: 2,
                        height: 20,
                        child: ColoredBox(color: Color(0xFF8070FF)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
