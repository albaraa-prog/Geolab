import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; 
import 'package:geolab/config/theme.dart';
import 'package:geolab/utils/responsive_layout.dart';
import 'package:flutter_svg/flutter_svg.dart';
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.85),
              AppTheme.primaryDarkColor,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with Scale and Fade animation
              SvgPicture.asset(
                'assets/images/rock_logo.svg',
                width: ResponsiveLayout.getResponsiveIconSize(context,
                    mobile: 200, tablet: 240, desktop: 300),
                height: ResponsiveLayout.getResponsiveIconSize(context,
                    mobile: 200, tablet: 240, desktop: 300),
              )
            .animate()
            .fade(duration: 800.ms, curve: Curves.easeOut)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 800.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 32),

            // Title with Slide and Fade animation
            Text(
              'Geolab',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            )
            .animate()
            .fade(duration: 800.ms, delay: 200.ms)
            .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOut),

            const SizedBox(height: 12),

            // Subtitle with Fade animation
            Text(
              'Rock Classification AI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 3.0,
              ),
              textAlign: TextAlign.center,
            )
            .animate()
            .fade(duration: 800.ms, delay: 400.ms),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
