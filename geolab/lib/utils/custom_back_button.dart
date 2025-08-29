import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      icon: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(3.14159), // Flip horizontally
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight01,
          size: size,
          color: color ?? const Color(0xFF000000),
        ),
      ),
    );
  }
}
