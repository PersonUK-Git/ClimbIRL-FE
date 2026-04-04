import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';
import '../../models/achievement_model.dart';

class ProfileState extends Equatable {
  final UserModel user;
  final List<AchievementModel> achievements;

  const ProfileState({
    required this.user,
    this.achievements = const [],
  });

  List<AchievementModel> get unlockedAchievements =>
      achievements.where((a) => a.isUnlocked).toList();

  List<AchievementModel> get lockedAchievements =>
      achievements.where((a) => !a.isUnlocked).toList();

  ProfileState copyWith({
    UserModel? user,
    List<AchievementModel>? achievements,
  }) {
    return ProfileState(
      user: user ?? this.user,
      achievements: achievements ?? this.achievements,
    );
  }

  @override
  List<Object?> get props => [user, achievements];
}
