import 'package:equatable/equatable.dart';

class LeaderboardEntryModel extends Equatable {
  final String userId;
  final String name;
  final String username;
  final String avatarUrl;
  final int totalXP;
  final int level;
  final int rank;

  const LeaderboardEntryModel({
    required this.userId,
    required this.name,
    required this.username,
    this.avatarUrl = '',
    required this.totalXP,
    required this.level,
    required this.rank,
  });

  @override
  List<Object?> get props => [
        userId,
        name,
        username,
        avatarUrl,
        totalXP,
        level,
        rank,
      ];
}
