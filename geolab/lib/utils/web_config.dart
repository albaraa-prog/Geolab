import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebConfig {
  static const bool isWeb = kIsWeb;
  
  // Web-specific breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double wideDesktopBreakpoint = 1600;
  
  // Web-specific constraints
  static const double maxContentWidth = 1200;
  static const double maxFormWidth = 500;
  static const double maxCardWidth = 400;
  
  // Web-specific spacing
  static const double webPadding = 32.0;
  static const double webMargin = 24.0;
  static const double webBorderRadius = 16.0;
  
  // Web-specific shadows
  static const List<BoxShadow> webShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> webElevatedShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];
  
  // Web-specific animations
  static const Duration webAnimationDuration = Duration(milliseconds: 300);
  static const Curve webAnimationCurve = Curves.easeInOut;
  
  // Web-specific responsive values
  static double getResponsiveValue({
    required double mobile,
    required double tablet,
    required double desktop,
    double? wideDesktop,
  }) {
    if (wideDesktop != null && _isWideDesktop()) {
      return wideDesktop;
    } else if (_isDesktop()) {
      return desktop;
    } else if (_isTablet()) {
      return tablet;
    } else {
      return mobile;
    }
  }
  
  static bool _isMobile() => _getScreenWidth() < mobileBreakpoint;
  static bool _isTablet() => _getScreenWidth() >= mobileBreakpoint && _getScreenWidth() < tabletBreakpoint;
  static bool _isDesktop() => _getScreenWidth() >= tabletBreakpoint && _getScreenWidth() < wideDesktopBreakpoint;
  static bool _isWideDesktop() => _getScreenWidth() >= wideDesktopBreakpoint;
  
  static double _getScreenWidth() {
    // This would need to be implemented with MediaQuery in actual widgets
    // For now, return a default value
    return 1200;
  }
}
