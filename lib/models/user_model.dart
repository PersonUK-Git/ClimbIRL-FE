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
  final String email;
  final String gender;
  final DateTime? dateOfBirth;
  final int? rank; // New field for leaderboard rank

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
    this.email = '',
    this.gender = '',
    this.dateOfBirth,
    this.rank,
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
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    int? rank,
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
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      rank: rank ?? this.rank,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseId(json['_id'] ?? json['id']),
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      totalXP: json['totalXP'] ?? 0,
      level: json['level'] ?? 1,
      title: json['title'] ?? 'Newcomer',
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      tasksCompleted: json['tasksCompleted'] ?? 0,
      achievementsUnlocked: json['achievementsUnlocked'] ?? 0,
      weeklyXP: _parseWeeklyXP(json['weeklyXP']),
      streakDays: _parseStreakDays(json['streakDays']),
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: _parseDate(json['dateOfBirth']),
      rank: json['rank'],
    );
  }

  static String _parseId(dynamic id) {
    if (id is String) return id;
    if (id is Map && id.containsKey('\$oid')) return id['\$oid'].toString();
    return id?.toString() ?? '';
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is String) return DateTime.tryParse(date);
    if (date is Map && date.containsKey('\$date')) {
      final value = date['\$date'];
      if (value is String) return DateTime.tryParse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  static List<int> _parseWeeklyXP(dynamic json) {
    if (json == null || json is! List || json.isEmpty) {
      return const [0, 0, 0, 0, 0, 0, 0];
    }
    try {
      final list = List<int>.from(json);
      if (list.length < 7) {
        return [...list, ...List.filled(7 - list.length, 0)];
      }
      return list.sublist(0, 7);
    } catch (e) {
      return const [0, 0, 0, 0, 0, 0, 0];
    }
  }

  static List<bool> _parseStreakDays(dynamic json) {
    if (json == null || json is! List || json.isEmpty) {
      return const [false, false, false, false, false, false, false];
    }
    try {
      final list = List<bool>.from(json);
      if (list.length < 7) {
        return [...list, ...List.filled(7 - list.length, false)];
      }
      return list.sublist(0, 7);
    } catch (e) {
      return const [false, false, false, false, false, false, false];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'avatarUrl': avatarUrl,
      'totalXP': totalXP,
      'level': level,
      'title': title,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'tasksCompleted': tasksCompleted,
      'achievementsUnlocked': achievementsUnlocked,
      'weeklyXP': weeklyXP,
      'streakDays': streakDays,
      'email': email,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'rank': rank,
    };
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
        email,
        gender,
        dateOfBirth,
        rank,
      ];
}
