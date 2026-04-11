import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../cubits/task/task_cubit.dart';
import '../../cubits/leaderboard/leaderboard_cubit.dart';
import '../../cubits/onboarding/onboarding_cubit.dart';
import '../../data/repositories/api_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  int _timerSeconds = 30;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timerSeconds = 30;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final apiRepository = context.read<ApiRepository>();
    final success = await apiRepository.sendOtp(email);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        setState(() => _isOtpSent = true);
        _startTimer();
      } else {
        // In a real app, you'd parse the status code or error body
        // For now, we'll show a helpful message suggesting registration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User not found. Please register first via the Onboarding screen.'),
            backgroundColor: Colors.orangeAccent,
            action: SnackBarAction(
              label: 'REGISTER',
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.pop(context);
                } else {
                  context.read<OnboardingCubit>().resetOnboarding();
                }
              },
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    String otp = _otpControllers.map((e) => e.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final apiRepository = context.read<ApiRepository>();
    final user = await apiRepository.verifyOtp(_emailController.text.trim(), otp);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (user != null) {
        // Success: Update AuthCubit and refresh data
        context.read<AuthCubit>().login(user);
        
        context.read<ProfileCubit>().loadProfile();
        context.read<TaskCubit>().loadTasks();
        context.read<LeaderboardCubit>().loadLeaderboard();
        
        // We don't need to pop, as app.dart will rebuild and show AppBottomNav
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.05),
                  cs.surface,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                    )
                  else
                    const SizedBox(height: 48), // Spacer to maintain consistent layout
                  const SizedBox(height: 40),
                  
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _isOtpSent ? _buildOtpView(cs) : _buildEmailView(cs),
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildEmailView(ColorScheme cs) {
    return Column(
      key: const ValueKey('email_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ).animate().fadeIn().slideX(begin: -0.1, end: 0),
        const SizedBox(height: 8),
        Text(
          'Enter your email to receive a verification code.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 48),
        
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
        
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Send Verification Code',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildOtpView(ColorScheme cs) {
    return Column(
      key: const ValueKey('otp_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Email',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ).animate().fadeIn().slideX(begin: -0.1, end: 0),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: 'We\'ve sent a 6-digit code to '),
              TextSpan(
                text: _emailController.text,
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 48),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildOtpDigitField(index, cs)),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
        
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Verify & Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: 24),
        
        Center(
          child: TextButton(
            onPressed: _timerSeconds == 0 ? _handleSendOtp : null,
            child: Text(
              _timerSeconds == 0 
                ? 'Resend Code' 
                : 'Resend in ${_timerSeconds}s',
              style: TextStyle(
                color: _timerSeconds == 0 ? cs.primary : cs.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildOtpDigitField(int index, ColorScheme cs) {
    return SizedBox(
      width: 50,
      height: 60,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
