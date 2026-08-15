import 'package:flutter/material.dart';

import '../_core.dart';

class AppTextStyle {
  AppTextStyle._();

  /// `fsize: 16, color: labelPrimary, weight: medium`
  static TextStyle get subtitle3 => TextStyle(
    color: AppColors.labelPrimary.withValues(alpha: 0.75),
    fontSize: AppDimens.size3M,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
  );

  /// for loading title `fsize: 16, color: gray100, weight: medium, spacing: 0.35`
  static TextStyle get titleLoading => TextStyle(
    color: AppColors.grey.shade100,
    fontSize: AppDimens.size3M,
    fontWeight: FontWeight.w500,
    wordSpacing: 0.35,
  );

  /// for dialog title `fsize: 24, color: labelPrimary, weight: semi-bold`
  static TextStyle get dialogTitle => const TextStyle(
    color: AppColors.labelPrimary,
    fontSize: AppDimens.sizeL,
    fontWeight: FontWeight.w600,
  );

  /// for dialog title `fsize: 16, color: labelSecondary, weight: reguler`
  static TextStyle get dialogDesc => TextStyle(
    color: AppColors.labelSecondary,
    fontSize: AppDimens.size3M,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Text Field Styles

  /// for text field labels `fsize: 14, color: labelPrimary, weight: semi-bold`
  static TextStyle get fieldLabel => const TextStyle(
    color: AppColors.labelPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// for text field input text `fsize: 16, color: labelPrimary, weight: medium`
  static TextStyle get fieldInput => const TextStyle(
    color: AppColors.labelPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  /// for text field hint text `fsize: 16, color: labelSecondary, weight: regular`
  static TextStyle get fieldHint => TextStyle(
    color: AppColors.labelSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
  );

  /// for text field error text `fsize: 12, color: red, weight: medium`
  static TextStyle get fieldError => const TextStyle(
    color: AppColors.red,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  /// for text field helper text `fsize: 12, color: labelTertiary, weight: regular`
  static TextStyle get fieldHelper => TextStyle(
    color: AppColors.labelTertiary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  /// for form section title `fsize: 18, color: labelPrimary, weight: semi-bold`
  static TextStyle get formSection => const TextStyle(
    color: AppColors.labelPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  /// for required field indicator `fsize: 14, color: red, weight: medium`
  static TextStyle get fieldRequired => const TextStyle(
    color: AppColors.red,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
