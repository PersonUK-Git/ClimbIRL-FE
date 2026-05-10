import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';
import '../../models/achievement_model.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  final UserModel user;
  final List<AchievementModel> achievements;
  final ProfileStatus status;
  final String? errorMessage;
  final List<dynamic> milestones;

  const ProfileState({
    required this.user,
    this.achievements = const [],
    this.status = ProfileStatus.initial,
    this.errorMessage,
    this.milestones = const [],
  });

  List<AchievementModel> get unlockedAchievements =>
      achievements.where((a) => a.isUnlocked).toList();

  List<AchievementModel> get lockedAchievements =>
      achievements.where((a) => !a.isUnlocked).toList();

  ProfileState copyWith({
    UserModel? user,
    List<AchievementModel>? achievements,
    ProfileStatus? status,
    String? errorMessage,
    List<dynamic>? milestones,
  }) {
    return ProfileState(
      user: user ?? this.user,
      achievements: achievements ?? this.achievements,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      milestones: milestones ?? this.milestones,
    );
  }

  @override
  List<Object?> get props => [user, achievements, status, errorMessage, milestones];
}

