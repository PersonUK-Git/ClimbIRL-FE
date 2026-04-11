import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/api_repository.dart';
import '../../models/user_model.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ApiRepository repository;

  ProfileCubit({required this.repository})
      : super(const ProfileState(
          user: UserModel(id: '', name: '', username: ''),
          achievements: [],
        ));

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final user = await repository.getProfile();
      final achievements = await repository.getAchievements();
      
      if (user != null) {
        emit(state.copyWith(
          user: user, 
          achievements: achievements,
          status: ProfileStatus.success,
        ));
      } else {
        emit(state.copyWith(status: ProfileStatus.failure, errorMessage: 'User profile not found'));
      }
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, errorMessage: e.toString()));
    }
  }


  void updateFromUser(UserModel user) async {
    final achievements = await repository.getAchievements();
    emit(state.copyWith(user: user, achievements: achievements));
  }

  void addXP(int xp) {
    // This is now handled by the backend when completing a task,
    // but the UI might still call it. We refresh to stay in sync.
    loadProfile();
  }

  Future<bool> updateUser(UserModel newUser) async {
    final updatedUser = await repository.updateProfile(newUser);
    if (updatedUser != null) {
      emit(state.copyWith(user: updatedUser));
      return true;
    }
    return false;
  }

  Future<bool> register(UserModel newUser) async {
    final user = await repository.register(newUser);
    if (user != null) {
      emit(state.copyWith(user: user));
      return true;
    }
    return false;
  }
}
