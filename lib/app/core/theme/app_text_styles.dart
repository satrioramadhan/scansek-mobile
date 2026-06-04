import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App text styles - Clean typography system
class AppTextStyles {
  AppTextStyles._(); // Private constructor

  // Base font family - Using Inter for clean, modern look
  static String get _fontFamily => GoogleFonts.inter().fontFamily!;

  // ============================================
  // HEADINGS
  // ============================================

  /// H1 - 32px Bold - For page titles
  static TextStyle get h1 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  /// H2 - 24px Bold - For section titles
  static TextStyle get h2 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// H3 - 20px SemiBold - For card titles
  static TextStyle get h3 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// H4 - 18px SemiBold - For subsection titles
  static TextStyle get h4 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ============================================
  // BODY TEXT
  // ============================================

  /// Body Large - 16px Regular - For main content
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Body Medium - 14px Regular - For secondary content
  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  /// Body Small - 12px Regular - For tertiary content
  static TextStyle get bodySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // ============================================
  // BUTTON TEXT
  // ============================================

  /// Button Large - 16px SemiBold
  static TextStyle get buttonLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
        height: 1.2,
        letterSpacing: 0.5,
      );

  /// Button Medium - 14px SemiBold
  static TextStyle get buttonMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
        height: 1.2,
        letterSpacing: 0.5,
      );

  /// Button Small - 12px SemiBold
  static TextStyle get buttonSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
        height: 1.2,
        letterSpacing: 0.3,
      );

  // ============================================
  // CAPTION & LABEL
  // ============================================

  /// Caption - 12px Regular - For hints and captions
  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
        height: 1.3,
      );

  /// Label - 12px Medium - For form labels
  static TextStyle get label => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.3,
      );

  /// Overline - 10px Medium - For small labels
  static TextStyle get overline => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.2,
        letterSpacing: 0.5,
      );

  // ============================================
  // SPECIAL STYLES
  // ============================================

  /// Display Large - 48px Bold - For big numbers in tracker cards
  static TextStyle get displayLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  /// Display Medium - 36px Bold - For medium numbers
  static TextStyle get displayMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  /// Display Small - 28px Bold - For small numbers
  static TextStyle get displaySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  /// Link - 14px Medium - For clickable text
  static TextStyle get link => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
        height: 1.5,
        decoration: TextDecoration.underline,
      );

  /// Error - 12px Regular - For error messages
  static TextStyle get error => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.error,
        height: 1.3,
      );
}
