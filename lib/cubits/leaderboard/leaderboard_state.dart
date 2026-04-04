import 'package:equatable/equatable.dart';
import '../../models/leaderboard_entry_model.dart';

enum LeaderboardPeriod { weekly, monthly, allTime }

class LeaderboardState extends Equatable {
  final List<LeaderboardEntryModel> entries;
  final LeaderboardPeriod period;
  final String currentUserId;

  const LeaderboardState({
    this.entries = const [],
    this.period = LeaderboardPeriod.weekly,
    this.currentUserId = 'user_001',
  });

  List<LeaderboardEntryModel> get top3 =>
      entries.where((e) => e.rank <= 3).toList();

  List<LeaderboardEntryModel> get restOfList =>
      entries.where((e) => e.rank > 3).toList();

  LeaderboardEntryModel? get currentUserEntry {
    try {
      return entries.firstWhere((e) => e.userId == currentUserId);
    } catch (_) {
      return null;
    }
  }

  LeaderboardState copyWith({
    List<LeaderboardEntryModel>? entries,
    LeaderboardPeriod? period,
    String? currentUserId,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      period: period ?? this.period,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  @override
  List<Object?> get props => [entries, period, currentUserId];
}
