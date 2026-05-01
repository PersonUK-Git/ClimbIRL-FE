import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../cubits/profile/profile_state.dart';
import 'widgets/xp_progress_card.dart';
import 'widgets/daily_streak_card.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/today_tasks_section.dart';
import 'widgets/dashboard_skeleton.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _celebrate() {
    _confettiController.play();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state.status == ProfileStatus.loading ||
            state.status == ProfileStatus.initial) {
          return const SafeArea(
            bottom: false,
            child: DashboardSkeleton(),
          );
        }

        return SafeArea(
          bottom: false,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: tt.bodyMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    state.user.name.split(' ').first,
                                    style: tt.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              // Avatar
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  state.user.name.isNotEmpty
                                      ? state.user.name[0].toUpperCase()
                                      : 'U',
                                  style: tt.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 400.ms).slideY(
                                begin: -0.1,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.easeOut,
                              ),

                          const SizedBox(height: 20),

                          // XP Progress Card
                          const XPProgressCard()
                              .animate()
                              .fadeIn(delay: 100.ms, duration: 500.ms)
                              .slideY(
                                begin: 0.05,
                                end: 0,
                                delay: 100.ms,
                                duration: 500.ms,
                                curve: Curves.easeOut,
                              ),

                          const SizedBox(height: 16),

                          // Daily Streak
                          const DailyStreakCard()
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 500.ms)
                              .slideY(
                                begin: 0.05,
                                end: 0,
                                delay: 200.ms,
                                duration: 500.ms,
                                curve: Curves.easeOut,
                              ),

                          const SizedBox(height: 16),

                          // Quick Stats
                          const QuickStatsRow()
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 500.ms)
                              .slideY(
                                begin: 0.05,
                                end: 0,
                                delay: 300.ms,
                                duration: 500.ms,
                                curve: Curves.easeOut,
                              ),

                          const SizedBox(height: 20),

                          // Today Tasks
                          TodayTasksSection(onCompleted: _celebrate)
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 500.ms),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
              // Confetti overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.1,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                    AppColors.xpGold,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }
}
