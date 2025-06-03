import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
  
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  
  factory StatusBanner.warning(String message) {
    return StatusBanner(
      message: message,
      //backgroundColor: AppColors.warningLight,
      backgroundColor: AppConstants.warningColor.shade100,
      textColor: AppColors.warningDark,
      icon: Icons.warning,
    );
  }
  
  factory StatusBanner.error(String message) {
    return StatusBanner(
      message: message,
      backgroundColor: AppColors.errorLight,
      textColor: AppColors.errorDark,
      icon: Icons.error,
    );
  }
  
  factory StatusBanner.success(String message) {
    return StatusBanner(
      message: message,
      backgroundColor: AppColors.successLight,
      textColor: AppColors.successDark,
      icon: Icons.check_circle,
    );
  }
  
  factory StatusBanner.info(String message) {
    return StatusBanner(
      message: message,
      backgroundColor: AppColors.infoLight,
      textColor: AppColors.infoDark,
      icon: Icons.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}