
import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  static const Color appBarBackgroundColor = Color.fromARGB(255, 35, 33, 46);
  
  // Primary Colors (MaterialColor for shade access)
  //static const MaterialColor primary = Colors.blue;
  static const Color primary = Color.fromARGB(255, 29, 52, 228);
  static const MaterialColor success = Colors.green;
  static const MaterialColor error = Colors.red;
  static const MaterialColor warning = Colors.orange;
  static const MaterialColor info = Colors.blue;
  
  // Light Theme Colors
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onBackground = Color(0xFF1A1A1A);
  
  // Success Colors
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color successMain = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF2E7D32);
  static const Color onSuccess = Colors.white;
  
  // Error Colors
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorMain = Color(0xFFF44336);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color onError = Colors.white;
  
  // Warning Colors
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color warningMain = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFE65100);
  static const Color onWarning = Colors.white;
  
  // Info Colors
  static const Color infoLight = Color(0xFFE3F2FD);
  //static const Color infoMain = Color(0xFF2196F3);
  static const Color infoMain = Color.fromARGB(255, 36, 61, 228);
  static const Color infoDark = Color(0xFF1976D2);
  static const Color onInfo = Colors.white;
  
  // Neutral Colors
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Status Indicator Colors
  static Color get readyStatus => success;
  static Color get pendingStatus => warning;
  static Color get errorStatus => error;
  
  // Helper methods for creating color variations
  static Color withAlpha(Color color, double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return color.withValues(alpha: opacity);
  }
  
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  // Predefined opacity variations for common use cases
  static Color get grey300WithAlpha30 => grey300.withValues(alpha: 0.3);
  static Color get warningMainWithAlpha30 => warningMain.withValues(alpha: 0.3);
  static Color get errorMainWithAlpha30 => errorMain.withValues(alpha: 0.3);
  static Color get successMainWithAlpha30 => successMain.withValues(alpha: 0.3);
  static Color get infoMainWithAlpha30 => infoMain.withValues(alpha: 0.3);
}
