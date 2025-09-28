import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Lottie animation constants and utilities
class LottieAnimations {
  // Animation paths
  static const String loading = 'assets/animations/loading.json';
  static const String success = 'assets/animations/success.json';
  static const String error = 'assets/animations/error.json';
  static const String camera = 'assets/animations/camera.json';
  static const String rock = 'assets/animations/rock.json';
  static const String welcome = 'assets/animations/welcome.json';
  static const String empty = 'assets/animations/empty.json';

  /// Create a loading animation
  static Widget loadingAnimation({
    double? width,
    double? height,
    Color? color,
  }) {
    return Lottie.asset(
      loading,
      width: width,
      height: height,
      repeat: true,
    );
  }

  /// Create a success animation
  static Widget successAnimation({
    double? width,
    double? height,
    VoidCallback? onCompleted,
  }) {
    return Lottie.asset(
      success,
      width: width,
      height: height,
      repeat: false,
      onLoaded: (composition) {
        if (onCompleted != null) {
          Future.delayed(composition.duration, onCompleted);
        }
      },
    );
  }

  /// Create an error animation
  static Widget errorAnimation({
    double? width,
    double? height,
    VoidCallback? onCompleted,
  }) {
    return Lottie.asset(
      error,
      width: width,
      height: height,
      repeat: false,
      onLoaded: (composition) {
        if (onCompleted != null) {
          Future.delayed(composition.duration, onCompleted);
        }
      },
    );
  }

  /// Create a camera animation
  static Widget cameraAnimation({
    double? width,
    double? height,
    bool repeat = true,
  }) {
    return Lottie.asset(
      camera,
      width: width,
      height: height,
      repeat: repeat,
    );
  }

  /// Create a rock animation
  static Widget rockAnimation({
    double? width,
    double? height,
    bool repeat = true,
  }) {
    return Lottie.asset(
      rock,
      width: width,
      height: height,
      repeat: repeat,
    );
  }

  /// Create a welcome animation
  static Widget welcomeAnimation({
    double? width,
    double? height,
    VoidCallback? onCompleted,
  }) {
    return Lottie.asset(
      welcome,
      width: width,
      height: height,
      repeat: false,
      onLoaded: (composition) {
        if (onCompleted != null) {
          Future.delayed(composition.duration, onCompleted);
        }
      },
    );
  }

  /// Create an empty state animation
  static Widget emptyAnimation({
    double? width,
    double? height,
    bool repeat = true,
  }) {
    return Lottie.asset(
      empty,
      width: width,
      height: height,
      repeat: repeat,
    );
  }
}
