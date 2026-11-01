import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Provides light and dark ThemeData for ClimbIRL.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.ink,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.lightWash,
          onPrimaryContainer: AppColors.ink,
          secondary: AppColors.signal,
          onSecondary: AppColors.white,
          tertiary: AppColors.signal,
          onTertiary: AppColors.white,
          error: AppColors.signal,
          onError: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.lightMuted,
          outline: AppColors.lightMuted,
          outlineVariant: AppColors.lightHairline,
          surfaceContainerLowest: AppColors.white,
          surfaceContainerLow: AppColors.white,
          surfaceContainer: AppColors.white,
          surfaceContainerHigh: AppColors.white,
          surfaceContainerHighest: AppColors.lightWash,
          inverseSurface: AppColors.ink,
          onInverseSurface: AppColors.white,
          surfaceTint: Colors.transparent,
        ),
        background: AppColors.lightBackground,
        overlay: SystemUiOverlayStyle.dark,
      );

  static ThemeData get dark => _build(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.white,
          onPrimary: AppColors.black,
          primaryContainer: AppColors.darkWash,
          onPrimaryContainer: AppColors.white,
          secondary: AppColors.signalBright,
          onSecondary: AppColors.black,
          tertiary: AppColors.signalBright,
          onTertiary: AppColors.black,
          error: AppColors.signalBright,
          onError: AppColors.black,
          surface: AppColors.darkSurface,
          onSurface: AppColors.white,
          onSurfaceVariant: AppColors.darkMuted,
          outline: AppColors.darkMuted,
          outlineVariant: AppColors.darkHairline,
          surfaceContainerLowest: AppColors.darkSurface,
          surfaceContainerLow: AppColors.darkSurface,
          surfaceContainer: AppColors.darkSurface,
          surfaceContainerHigh: AppColors.darkSurface,
          surfaceContainerHighest: AppColors.darkWash,
          inverseSurface: AppColors.white,
          onInverseSurface: AppColors.black,
          surfaceTint: Colors.transparent,
        ),
        background: AppColors.black,
        overlay: SystemUiOverlayStyle.light,
      );

  static ThemeData _build(
    ColorScheme cs, {
    required Color background,
    required SystemUiOverlayStyle overlay,
  }) {
    final textTheme = AppTextStyles.textTheme;
    const buttonShape = StadiumBorder();
    final buttonText = textTheme.labelLarge?.copyWith(fontSize: 15);
    const buttonSize = Size(64, 54);

    OutlineInputBorder inputBorder([Color? color, double width = 1.25]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: color == null
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: cs.brightness,
      colorScheme: cs,
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlay,
        titleTextStyle: textTheme.headlineMedium?.copyWith(color: cs.onSurface),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
          disabledBackgroundColor: cs.surfaceContainerHighest,
          disabledForegroundColor: cs.onSurfaceVariant,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          elevation: 0,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outlineVariant),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.onSurface,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: cs.onSurface),
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: cs.inverseSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: cs.onInverseSurface),
        actionTextColor: cs.onInverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        modalBackgroundColor: cs.surface,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: cs.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        labelStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        hintStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        prefixIconColor: cs.onSurfaceVariant,
        border: inputBorder(),
        enabledBorder: inputBorder(),
        focusedBorder: inputBorder(cs.onSurface),
        errorBorder: inputBorder(cs.error),
        focusedErrorBorder: inputBorder(cs.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHighest,
      ),
    );
  }
}
