import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:geolab/Service/theme_service.dart';
import 'package:geolab/features/Settings/components/localization.dart';
import 'package:provider/provider.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    
    return Consumer<LocalizationService>(
      builder: (context, localizationService, _) {
        // Determine arrow direction based on language
        final isRTL = localizationService.isRTL;
        final arrowIcon = isRTL 
            ? HugeIcons.strokeRoundedArrowRight01  // Right arrow for RTL
            : HugeIcons.strokeRoundedArrowLeft01;  // Left arrow for LTR (English)
        
        // Always use white color for the back button
        Color buttonColor = color ?? Colors.white;
        
        return IconButton(
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
          icon: HugeIcon(
            icon: arrowIcon,
            size: size,
            color: buttonColor,
          ),
        );
      },
    );
  }
}
