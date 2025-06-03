import 'package:flutter/material.dart';

class AppConstants {
  // Prevent instantiation
  AppConstants._();
  
  static const String appTitle = 'Plugin Generator';
  static const String bitbucketUsernameKey = 'bitbucket_username';
  static const String bitbucketPasswordKey = 'bitbucket_app_password';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardPadding = 20.0;
  static const double buttonHeight = 16.0;
  static const double borderRadius = 8.0;
  
  // Colors - Use MaterialColor for shade access
  static const MaterialColor successColor = Colors.green;
  static const MaterialColor errorColor = Colors.red;
  static const MaterialColor warningColor = Colors.orange;
  static const MaterialColor infoColor = Colors.blue;
}
/*
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppConstants {
  // Prevent instantiation
  AppConstants._();
  
  static const String appTitle = 'WPMU DEV ODD Plugin Generator';
  static const String bitbucketUsernameKey = 'bitbucket_username';
  static const String bitbucketPasswordKey = 'bitbucket_app_password';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardPadding = 20.0;
  static const double buttonHeight = 16.0;
  static const double borderRadius = 8.0;
  
  // Colors - Now using AppColors
  static MaterialColor get successColor => AppColors.success;
  static MaterialColor get errorColor => AppColors.error;
  static MaterialColor get warningColor => AppColors.warning;
  static MaterialColor get infoColor => AppColors.info;
  static Color get appBarBackground => AppColors.appBarBackgroundColor;
}
*/