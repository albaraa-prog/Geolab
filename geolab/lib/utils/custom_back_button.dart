import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:geolab/config/theme_service.dart';
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
        return IconButton(
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
          icon: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(localizationService.isRTL ? 3.14159 : 0), // Flip for RTL, normal for LTR
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: size,
              color: color ?? themeService.primaryColor,
            ),
          ),
        );
      },
    );
  }
}
