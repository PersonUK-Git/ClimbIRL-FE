import 'package:flutter/material.dart';
import 'package:animated_scale_nav_bar/animated_scale_nav_bar.dart';
import '../core/theme/app_colors.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppBottomNav extends StatefulWidget {
  const AppBottomNav({super.key});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final _screens = const [
    DashboardScreen(),
    TasksScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        physics: const BouncingScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Container(
            height: 80, // Package default height
            color: isDark ? AppColors.navBarDark : AppColors.navBarLight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const barHeight = 46.0;
                return Center(
                  child: SizedBox(
                    height: 80,
                    child: MediaQuery(
                      // Sync internal offsets with the actual bar width
                      data: MediaQuery.of(context).copyWith(
                        size: Size(constraints.maxWidth, 75),
                      ),
                      child: AnimatedNavBar(
                        selectedIndex: _currentIndex,
                        pageController: _pageController,
                        backgroundColor: Colors.transparent,
                        selectedItemColor: AppColors.white,
                        unselectedItemColor: AppColors.white.withValues(alpha: 0.5),
                        indicatorColor: AppColors.white.withValues(alpha: 0.14),
                        icons: const [
                          Icons.home_rounded,
                          Icons.task_alt_rounded,
                          Icons.leaderboard_rounded,
                          Icons.person_rounded,
                        ],
                        onTabSelected: (index) {
                          setState(() => _currentIndex = index);
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          );
                        },
                        borderRadius: BorderRadius.circular(35),
                        height: barHeight,
                        indicatorHeight: barHeight,
                        indicatorWidth: 72,
                        iconSize: 25,
                        indicatorBorderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
