import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'cubits/theme/theme_cubit.dart';
import 'cubits/theme/theme_state.dart';
import 'cubits/task/task_cubit.dart';
import 'cubits/profile/profile_cubit.dart';
import 'cubits/leaderboard/leaderboard_cubit.dart';
import 'widgets/app_bottom_nav.dart';

class ClimbIRLApp extends StatelessWidget {
  const ClimbIRLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => TaskCubit()),
        BlocProvider(create: (_) => ProfileCubit()),
        BlocProvider(create: (_) => LeaderboardCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'ClimbIRL',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeState.themeMode,
            home: const AppBottomNav(),
          );
        },
      ),
    );
  }
}
