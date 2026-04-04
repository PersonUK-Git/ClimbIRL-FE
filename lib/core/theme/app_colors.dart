import 'package:flutter/material.dart';

/// Semantic color tokens for ClimbIRL.
/// These wrap around the Material 3 ColorScheme but add app-specific semantics.
class AppColors {
  AppColors._();

  // Brand seed
  static const Color seedColor = Color(0xFF6C63FF);

  // Difficulty colors
  static const Color easy = Color(0xFF4CAF50);
  static const Color medium = Color(0xFFFF9800);
  static const Color hard = Color(0xFFF44336);
  static const Color epic = Color(0xFF9C27B0);

  // XP / Level accent
  static const Color xpGold = Color(0xFFFFD700);
  static const Color streak = Color(0xFFFF6B35);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);

  // Light theme surfaces
  static const Color lightSurface = Color(0xFFF8F9FE);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF2F3F8);

  // Dark theme surfaces
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF222240);
  static const Color darkBackground = Color(0xFF12121F);

  /// Returns the difficulty color for a given difficulty string.
  static Color difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return easy;
      case 'medium':
        return medium;
      case 'hard':
        return hard;
      case 'epic':
        return epic;
      default:
        return easy;
    }
  }

  /// Returns XP value for a difficulty level.
  static int difficultyXP(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 25;
      case 'medium':
        return 50;
      case 'hard':
        return 100;
      case 'epic':
        return 200;
      default:
        return 25;
    }
  }
}
