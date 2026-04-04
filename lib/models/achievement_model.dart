import 'package:equatable/equatable.dart';

class AchievementModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String category; // Tasks, Streaks, Social, Special
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0
  final int target;
  final int current;
  final String rarity; // Common, Rare, Epic, Legendary
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.category,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.target = 1,
    this.current = 0,
    this.rarity = 'Common',
    this.unlockedAt,
  });

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    String? category,
    bool? isUnlocked,
    double? progress,
    int? target,
    int? current,
    String? rarity,
    DateTime? unlockedAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      category: category ?? this.category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      current: current ?? this.current,
      rarity: rarity ?? this.rarity,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        iconName,
        category,
        isUnlocked,
        progress,
        target,
        current,
        rarity,
        unlockedAt,
      ];
}
