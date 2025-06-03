import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = LogoSize.medium,
    this.showText = true,
    this.color,
  });

  final LogoSize size;
  final bool showText;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppColors.infoMain;
    
    switch (size) {
      case LogoSize.small:
        return _buildLogo(32, 14, logoColor);
      case LogoSize.medium:
        return _buildLogo(48, 18, logoColor);
      case LogoSize.large:
        return _buildLogo(64, 24, logoColor);
      case LogoSize.extraLarge:
        return _buildLogo(96, 32, logoColor);
    }
  }

  Widget _buildLogo(double iconSize, double textSize, Color logoColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // You can replace this with Image.asset() when you have a logo file
        _buildIconLogo(iconSize, logoColor),
        
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'Plugin Generator',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: logoColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIconLogo(double size, Color color) {
    // Option 1: Use an asset image (recommended)
    // return Image.asset(
    //   'assets/images/logo.png',
    //   width: size,
    //   height: size,
    //   color: color, // This tints the image
    // );

    // Option 2: Use a custom icon/symbol as placeholder
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Icon(
        Icons.extension,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}

enum LogoSize {
  small,
  medium, 
  large,
  extraLarge,
}