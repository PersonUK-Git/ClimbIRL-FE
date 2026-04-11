import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  static const String _onboardingKey = 'hasSeenOnboarding';

  OnboardingCubit() : super(OnboardingInitial());

  Future<void> checkOnboardingStatus() async {
    emit(OnboardingLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
      
      if (hasSeenOnboarding) {
        emit(OnboardingCompleted());
      } else {
        emit(OnboardingRequired());
      }
    } catch (e) {
      // If storage fails, default to showing onboarding
      emit(OnboardingRequired());
    }
  }

  Future<void> completeOnboarding() async {
    emit(OnboardingLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
      emit(OnboardingCompleted());
    } catch (e) {
      // Even if storage fails, we allow entry for the current session
      emit(OnboardingCompleted());
    }
  }

  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, false);
      emit(OnboardingRequired());
    } catch (e) {
      emit(OnboardingRequired());
    }
  }
}

