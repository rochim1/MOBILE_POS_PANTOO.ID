import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';

class AppTheme {
  AppTheme();

  static ThemeData light() {
    late ThemeData base = ThemeData.light();

    return base.copyWith(
      primaryColor: AppColors.primaryTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
        error: AppColors.red,
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.grey.shade900,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.grey.shade900,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.grey.shade900,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: AppColors.grey.shade800,
          height: 1.35,
        ),
      ),
      splashColor: AppColors.splash,
      primaryColorLight: AppColors.primaryTheme,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      dividerTheme: DividerThemeData(
        color: AppColors.grey.shade200,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.grey.shade200),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.primary.withValues(alpha: 0.14),
        side: BorderSide(color: AppColors.grey.shade200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        centerTitle: false,
        iconTheme: base.iconTheme.copyWith(color: AppColors.white),
        elevation: AppDimens.sizeZero,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge!.copyWith(
          color: AppColors.white,
          fontSize: AppDimens.size4M,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey.shade900,
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMediumX),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
          ),
          foregroundColor: AppColors.primary,
          minimumSize: const Size(AppDimens.size8X, AppDimens.size3XL),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMediumX),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
          ),
          foregroundColor: AppColors.white,
          backgroundColor: AppColors.secondary,
          disabledBackgroundColor: AppColors.fillTertiary,
          disabledForegroundColor: AppColors.labelSecondary,
          minimumSize: const Size(AppDimens.size8X, AppDimens.size3XL),
          shadowColor: AppColors.transparent,
          elevation: 0,
        ).copyWith(elevation: WidgetStateProperty.all<double>(0)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          side: const BorderSide(width: 1.0, color: AppColors.secondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMediumX),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
          ),
          minimumSize: const Size(AppDimens.size8X, AppDimens.size3XL),
          shadowColor: AppColors.transparent,
          elevation: 0,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.secondary),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          } else if (states.contains(WidgetState.hovered)) {
            return AppColors.splash;
          }
          return AppColors.fillPrimary;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          } else if (states.contains(WidgetState.hovered)) {
            return AppColors.splash;
          }
          return AppColors.fillPrimary;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.grey.shade200, width: 1),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.grey.shade200, width: 1),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.white,
        hintStyle: TextStyle(color: AppColors.grey.shade500),
        labelStyle: const TextStyle(color: AppColors.labelPrimary),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        contentPadding: const EdgeInsets.all(AppDimens.paddingMedium),
        errorStyle: const TextStyle(color: AppColors.red),
      ),
    );
  }
}
