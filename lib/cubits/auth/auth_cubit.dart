import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/api_repository.dart';
import '../../models/user_model.dart';
import '../../core/services/notification_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiRepository repository;

  AuthCubit({required this.repository}) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final token = await repository.getToken();
      if (token != null) {
        final user = await repository.getProfile();
        if (user != null) {
          emit(AuthAuthenticated(user));
          NotificationService().updateToken();
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> login(UserModel user) async {
    emit(AuthAuthenticated(user));
    NotificationService().updateToken();
  }

  Future<void> logout() async {
    await repository.clearToken();
    emit(AuthUnauthenticated());
  }
}
