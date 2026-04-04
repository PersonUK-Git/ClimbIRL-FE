import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/xp_utils.dart';
import '../../data/mock/mock_achievements.dart';
import '../../data/mock/mock_user.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit()
      : super(ProfileState(
          user: mockUser,
          achievements: List.from(mockAchievements),
        ));

  void addXP(int xp) {
    final newTotalXP = state.user.totalXP + xp;
    final newLevel = XPUtils.getLevel(newTotalXP);
    final newTitle = XPUtils.getLevelTitle(newLevel);

    // Update weekly XP (add to today)
    final weeklyXP = List<int>.from(state.user.weeklyXP);
    weeklyXP[6] = weeklyXP[6] + xp;

    emit(state.copyWith(
      user: state.user.copyWith(
        totalXP: newTotalXP,
        level: newLevel,
        title: newTitle,
        tasksCompleted: xp > 0
            ? state.user.tasksCompleted + 1
            : state.user.tasksCompleted - 1,
        weeklyXP: weeklyXP,
      ),
    ));
  }
}
