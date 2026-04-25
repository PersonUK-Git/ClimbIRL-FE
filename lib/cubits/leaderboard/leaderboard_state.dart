import 'package:equatable/equatable.dart';
import '../../models/leaderboard_entry_model.dart';

enum LeaderboardPeriod { weekly, monthly, allTime }
enum LeaderboardStatus { initial, loading, success, failure }

class LeaderboardState extends Equatable {
  final List<LeaderboardEntryModel> entries;
  final LeaderboardPeriod period;
  final String currentUserId;
  final LeaderboardStatus status;
  final String? errorMessage;

  const LeaderboardState({
    this.entries = const [],
    this.period = LeaderboardPeriod.weekly,
    this.currentUserId = '',
    this.status = LeaderboardStatus.initial,
    this.errorMessage,
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
    LeaderboardStatus? status,
    String? errorMessage,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      period: period ?? this.period,
      currentUserId: currentUserId ?? this.currentUserId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [entries, period, currentUserId, status, errorMessage];
}

