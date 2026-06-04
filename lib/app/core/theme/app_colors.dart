import 'package:flutter/material.dart';

/// App colors - Clean, minimal, white-based design dengan teal accent
class AppColors {
  AppColors._(); // Private constructor

  // Primary Colors (Teal)
  static const Color primary = Color(0xFF80CBC4); // Soft Teal from Dashboard
  static const Color primaryDark = Color(0xFF00897B);
  static const Color primaryLight = Color(0xFFB2DFDB);
  static const Color primarySuperLight = Color(0xFFE0F2F1);

  // Background
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFE0B2);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFBBDEFB);

  // Chart Colors (Pastel - sesuai gambar referensi)
  static const Color chartCaloriesConsumed = Color(0xFFFF6B9D);
  static const Color chartCaloriesBurned = Color(0xFF9896F0);
  static const Color chartSugar = Color(0xFFFFB74D);
  static const Color chartWater = Color(0xFF4FC3F7);
  static const Color chartActivityWalking = Color(0xFF81C784);
  static const Color chartActivityJogging = Color(0xFFFFD54F);
  static const Color chartActivityRunning = Color(0xFFFF8A65);

  // Aliases for dashboard cards
  static const Color chartOrange = Color(0xFFFF9800);
  static const Color chartGreen = Color(0xFF4CAF50);
  static const Color divider = Color(0xFFE0E0E0);

  // Grays
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // Borders & Dividers
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color border = borderColor; // Alias
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color focusBorderColor = primary;

  // Shadow Colors
  static const Color shadowColor = Color(0x1A000000); // 10% black
  static const Color cardShadow = Color(0x0D000000); // 5% black

  // Transparent
  static const Color transparent = Color(0x00000000);

  // Shimmer Colors (untuk loading)
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
