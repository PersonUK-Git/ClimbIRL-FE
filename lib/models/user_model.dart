import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final int totalXP;
  final int level;
  final String title;
  final int currentStreak;
  final int longestStreak;
  final int tasksCompleted;
  final int achievementsUnlocked;
  final List<int> weeklyXP; // Last 7 days XP
  final List<bool> streakDays; // Last 7 days streak

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl = '',
    this.totalXP = 0,
    this.level = 1,
    this.title = 'Newcomer',
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.tasksCompleted = 0,
    this.achievementsUnlocked = 0,
    this.weeklyXP = const [0, 0, 0, 0, 0, 0, 0],
    this.streakDays = const [false, false, false, false, false, false, false],
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? avatarUrl,
    int? totalXP,
    int? level,
    String? title,
    int? currentStreak,
    int? longestStreak,
    int? tasksCompleted,
    int? achievementsUnlocked,
    List<int>? weeklyXP,
    List<bool>? streakDays,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      title: title ?? this.title,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
      weeklyXP: weeklyXP ?? this.weeklyXP,
      streakDays: streakDays ?? this.streakDays,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        avatarUrl,
        totalXP,
        level,
        title,
        currentStreak,
        longestStreak,
        tasksCompleted,
        achievementsUnlocked,
        weeklyXP,
        streakDays,
      ];
}
