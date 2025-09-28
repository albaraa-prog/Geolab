import 'package:flutter/material.dart';
import 'package:geolab/config/animations/lottie_animations.dart';

/// Reusable animation widgets for the app
class AnimationWidgets {
  /// Loading animation with customizable size and color
  static Widget loading({
    double? width,
    double? height,
    Color? color,
    String? message,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LottieAnimations.loadingAnimation(
          width: width ?? 100,
          height: height ?? 100,
          color: color,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: color ?? Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Success animation with callback
  static Widget success({
    double? width,
    double? height,
    String? message,
    VoidCallback? onCompleted,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LottieAnimations.successAnimation(
          width: width ?? 120,
          height: height ?? 120,
          onCompleted: onCompleted,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Error animation with callback
  static Widget error({
    double? width,
    double? height,
    String? message,
    VoidCallback? onCompleted,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LottieAnimations.errorAnimation(
          width: width ?? 120,
          height: height ?? 120,
          onCompleted: onCompleted,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Camera animation for camera-related screens
  static Widget camera({
    double? width,
    double? height,
    bool repeat = true,
  }) {
    return LottieAnimations.cameraAnimation(
      width: width ?? 200,
      height: height ?? 200,
      repeat: repeat,
    );
  }

  /// Rock animation for geology-related screens
  static Widget rock({
    double? width,
    double? height,
    bool repeat = true,
  }) {
    return LottieAnimations.rockAnimation(
      width: width ?? 200,
      height: height ?? 200,
      repeat: repeat,
    );
  }

  /// Welcome animation for onboarding
  static Widget welcome({
    double? width,
    double? height,
    String? message,
    VoidCallback? onCompleted,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LottieAnimations.welcomeAnimation(
          width: width ?? 300,
          height: height ?? 300,
          onCompleted: onCompleted,
        ),
        if (message != null) ...[
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Empty state animation
  static Widget empty({
    double? width,
    double? height,
    String? message,
    String? subtitle,
    Widget? action,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LottieAnimations.emptyAnimation(
          width: width ?? 200,
          height: height ?? 200,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 24),
          action,
        ],
      ],
    );
  }

  /// Animated button with loading state
  static Widget animatedButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? backgroundColor,
    Color? textColor,
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: LottieAnimations.loadingAnimation(
                  width: 20,
                  height: 20,
                  color: textColor,
                ),
              )
            : Text(text),
      ),
    );
  }

  /// Animated icon button
  static Widget animatedIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? color,
    double? size,
  }) {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: size ?? 24,
              height: size ?? 24,
              child: LottieAnimations.loadingAnimation(
                width: size ?? 24,
                height: size ?? 24,
                color: color,
              ),
            )
          : Icon(icon, color: color, size: size),
    );
  }
}
