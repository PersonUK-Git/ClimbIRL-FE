import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../cubits/task/task_cubit.dart';
import '../../cubits/leaderboard/leaderboard_cubit.dart';
import '../../cubits/onboarding/onboarding_cubit.dart';
import '../../data/repositories/api_repository.dart';
import '../../widgets/dot_climb.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  late final List<FocusNode> _otpFocusNodes;

  bool _isOtpSent = false;
  bool _isLoading = false;
  int _timerSeconds = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _otpFocusNodes = List.generate(6, (index) {
      return FocusNode(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_otpControllers[index].text.isEmpty && index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
              _otpControllers[index - 1].clear();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
      );
    });
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User not found. Please register first via the Onboarding screen.'),
            action: SnackBarAction(
              label: 'Register',
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.pop(context);
                } else {
                  context.read<OnboardingCubit>().resetOnboarding();
                }
              },
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
        context.read<AuthCubit>().login(user);
        context.read<OnboardingCubit>().completeOnboarding();

        context.read<ProfileCubit>().loadProfile();
        context.read<TaskCubit>().loadTasks();
        context.read<LeaderboardCubit>().loadLeaderboard();

        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DotClimb(progress: 0.38, height: 120),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: _isOtpSent ? _buildOtpView(cs) : _buildEmailView(cs),
                  ),
                ],
              ),
            ),
          ),

          // Top Left Back Navigation Button
          if (Navigator.canPop(context))
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
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
    );
  }

  Widget _buildEmailView(ColorScheme cs) {
    final tt = Theme.of(context).textTheme;

    return Column(
      key: const ValueKey('email_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back.', style: tt.displaySmall),
        const SizedBox(height: 8),
        Text(
          'Enter your email to receive a verification code.',
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email address'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _handleSendOtp,
            child: const Text('Send verification code'),
          ),
        ),
        if (!Navigator.canPop(context)) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                context.read<OnboardingCubit>().resetOnboarding();
              },
              child: Text.rich(
                TextSpan(
                  text: "Don't have an account? ",
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  children: [
                    TextSpan(
                      text: 'Create one',
                      style: tt.labelLarge?.copyWith(color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildOtpView(ColorScheme cs) {
    final tt = Theme.of(context).textTheme;

    return Column(
      key: const ValueKey('otp_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Check your email.', style: tt.displaySmall),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: "We've sent a 6-digit code to ",
            style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            children: [
              TextSpan(
                text: _emailController.text,
                style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            for (var index = 0; index < 6; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(child: _buildOtpDigitField(index)),
            ],
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _handleVerifyOtp,
            child: const Text('Verify and log in'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _timerSeconds == 0 ? _handleSendOtp : null,
            child: Text(
              _timerSeconds == 0 ? 'Resend code' : 'Resend in ${_timerSeconds}s',
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildOtpDigitField(int index) {
    return TextField(
      controller: _otpControllers[index],
      focusNode: _otpFocusNodes[index],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 1,
      style: Theme.of(context).textTheme.headlineSmall,
      decoration: const InputDecoration(
        counterText: '',
        contentPadding: EdgeInsets.symmetric(vertical: 14),
      ),
      onChanged: (value) {
        if (value.isNotEmpty && index < 5) {
          _otpFocusNodes[index + 1].requestFocus();
        }
      },
    );
  }
}
