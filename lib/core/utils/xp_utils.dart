import '../constants/app_constants.dart';

/// Utility functions for XP and leveling calculations.
class XPUtils {
  XPUtils._();

  /// Get the current level based on total XP.
  static int getLevel(int totalXP) {
    for (int i = AppConstants.levelThresholds.length - 1; i >= 0; i--) {
      if (totalXP >= AppConstants.levelThresholds[i]) {
        return i + 1; // Levels are 1-indexed
      }
    }
    return 1;
  }

  /// Get the title for a given level.
  static String getLevelTitle(int level) {
    if (level < 1) return AppConstants.levelTitles[0];
    if (level > AppConstants.maxLevel) {
      return AppConstants.levelTitles[AppConstants.maxLevel - 1];
    }
    return AppConstants.levelTitles[level - 1];
  }

  /// XP needed from current level start to next level.
  static int xpForCurrentLevel(int totalXP) {
    final level = getLevel(totalXP);
    if (level >= AppConstants.maxLevel) {
      return 0; // Max level reached
    }
    final currentThreshold = AppConstants.levelThresholds[level - 1];
    final nextThreshold = AppConstants.levelThresholds[level];
    return nextThreshold - currentThreshold;
  }

  /// XP progress within the current level (0 to xpForCurrentLevel).
  static int xpProgressInLevel(int totalXP) {
    final level = getLevel(totalXP);
    if (level >= AppConstants.maxLevel) {
      return 0;
    }
    final currentThreshold = AppConstants.levelThresholds[level - 1];
    return totalXP - currentThreshold;
  }

  /// Progress fraction (0.0 to 1.0) within the current level.
  static double levelProgress(int totalXP) {
    final total = xpForCurrentLevel(totalXP);
    if (total == 0) return 1.0;
    return xpProgressInLevel(totalXP) / total;
  }

  /// XP remaining to reach next level.
  static int xpToNextLevel(int totalXP) {
    final total = xpForCurrentLevel(totalXP);
    final progress = xpProgressInLevel(totalXP);
    return total - progress;
  }
}
