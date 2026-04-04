import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/mock/mock_leaderboard.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit()
      : super(LeaderboardState(entries: List.from(mockLeaderboard)));

  void setPeriod(LeaderboardPeriod period) {
    emit(state.copyWith(period: period));
  }
}
