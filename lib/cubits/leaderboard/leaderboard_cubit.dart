import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/api_repository.dart';
import '../../models/leaderboard_entry_model.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final ApiRepository repository;

  LeaderboardCubit({required this.repository}) : super(const LeaderboardState());

  Future<void> loadLeaderboard() async {
    emit(state.copyWith(isLoading: true));
    
    // Map period enum to string for API
    final periodString = switch (state.period) {
      LeaderboardPeriod.weekly => 'weekly',
      LeaderboardPeriod.monthly => 'monthly',
      LeaderboardPeriod.allTime => 'allTime',
    };

    final users = await repository.getLeaderboard(period: periodString);
    
    // Map UserModel to LeaderboardEntryModel
    final entries = users.map((user) {
      return LeaderboardEntryModel(
        userId: user.id,
        name: user.name,
        username: user.username,
        avatarUrl: user.avatarUrl,
        totalXP: user.totalXP,
        level: user.level,
        rank: user.rank ?? 0,
      );
    }).toList();

    emit(state.copyWith(
      entries: entries,
      isLoading: false,
    ));
  }

  void setPeriod(LeaderboardPeriod period) {
    emit(state.copyWith(period: period));
    loadLeaderboard(); // Reload data for the new period
  }
}
