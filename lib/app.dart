import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'cubits/theme/theme_cubit.dart';
import 'cubits/theme/theme_state.dart';
import 'cubits/task/task_cubit.dart';
import 'cubits/profile/profile_cubit.dart';
import 'cubits/leaderboard/leaderboard_cubit.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/auth/auth_state.dart';
import 'cubits/onboarding/onboarding_cubit.dart';
import 'cubits/onboarding/onboarding_state.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/login/login_screen.dart';
import 'widgets/app_bottom_nav.dart';
import 'data/repositories/api_repository.dart';

class ClimbIRLApp extends StatefulWidget {
  const ClimbIRLApp({super.key});

  @override
  State<ClimbIRLApp> createState() => _ClimbIRLAppState();
}

class _ClimbIRLAppState extends State<ClimbIRLApp> {
  late final ApiRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = ApiRepository();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(
            create: (context) => AuthCubit(
              repository: _repository,
            )..checkAuthStatus(),
          ),
          BlocProvider(
            create: (context) => TaskCubit(
              repository: _repository,
            )..loadTasks(),
          ),
          BlocProvider(
            create: (context) => ProfileCubit(
              repository: _repository,
            )..loadProfile(),
          ),
          BlocProvider(
            create: (context) => LeaderboardCubit(
              repository: _repository,
            )..loadLeaderboard(),
          ),
          BlocProvider(
            create: (context) => OnboardingCubit()..checkOnboardingStatus(),
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            return BlocBuilder<OnboardingCubit, OnboardingState>(
              builder: (context, onboardingState) {
                return _LifecycleRefreshManager(
                  child: MaterialApp(
                    title: 'ClimbIRL',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: themeState.themeMode,
                    home: _getHome(authState, onboardingState),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _getHome(AuthState authState, OnboardingState onboardingState) {
    if (onboardingState is OnboardingInitial ||
        onboardingState is OnboardingLoading ||
        authState is AuthInitial ||
        authState is AuthLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (onboardingState is! OnboardingCompleted) {
      return const OnboardingScreen();
    } else if (authState is! AuthAuthenticated) {
      return const LoginScreen();
    } else {
      return const AppBottomNav();
    }
  }
}

/// Manages data refreshing based on app lifecycle and auth changes.
class _LifecycleRefreshManager extends StatefulWidget {
  final Widget child;
  const _LifecycleRefreshManager({required this.child});

  @override
  State<_LifecycleRefreshManager> createState() => _LifecycleRefreshManagerState();
}

class _LifecycleRefreshManagerState extends State<_LifecycleRefreshManager> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  void _refreshData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<TaskCubit>().loadTasks();
      context.read<ProfileCubit>().loadProfile();
      context.read<LeaderboardCubit>().loadLeaderboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _refreshData();
        }
      },
      child: widget.child,
    );
  }
}
