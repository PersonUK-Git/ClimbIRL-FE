import 'package:flutter/material.dart';

/// Colour tokens for ClimbIRL: black and white, with one signal red accent.
class AppColors {
  AppColors._();

  // Dark theme
  static const Color black = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF151515);
  static const Color darkWash = Color(0xFF262626);
  static const Color darkHairline = Color(0xFF2C2C2C);
  static const Color darkMuted = Color(0xFF9A9A9A);
  static const Color white = Color(0xFFFFFFFF);

  // Light theme
  static const Color lightBackground = Color(0xFFF2F2F2);
  static const Color lightWash = Color(0xFFECECEC);
  static const Color lightHairline = Color(0xFFDDDDDD);
  static const Color lightMuted = Color(0xFF6A6A6A);
  static const Color ink = Color(0xFF0B0B0B);

  // The one accent
  static const Color signal = Color(0xFFE5301F);
  static const Color signalBright = Color(0xFFFF4A36);

  // Floating navigation bar
  static const Color navBarLight = ink;
  static const Color navBarDark = Color(0xFF242424);

  static const List<Color> confetti = [signal, signalBright, darkMuted, lightHairline];

  /// Returns 1 (Easy) to 4 (Epic) for a difficulty string.
  static int difficultyLevel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      case 'epic':
        return 4;
      default:
        return 1;
    }
  }

  /// Returns the colour for an achievement rarity. Only Legendary gets the accent.
  static Color rarityColor(String rarity, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    if (rarity == 'Legendary') return dark ? signalBright : signal;
    return dark ? white : ink;
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
