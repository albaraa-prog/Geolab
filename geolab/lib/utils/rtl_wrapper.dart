import 'package:flutter/material.dart';
import 'package:geolab/features/Settings/components/localization.dart';
import 'package:provider/provider.dart';

/// A wrapper widget that provides RTL/LTR support
class RTLWrapper extends StatelessWidget {
  final Widget child;
  final bool forceDirection;
  final TextDirection? forcedDirection;

  const RTLWrapper({
    super.key,
    required this.child,
    this.forceDirection = false,
    this.forcedDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, _) {
        final textDirection = forcedDirection ??
            (localizationService.isRTL ? TextDirection.rtl : TextDirection.ltr);

        return Directionality(
          textDirection: textDirection,
          child: child,
        );
      },
    );
  }
}

/// A wrapper for RTL-aware layouts that need to handle both directions
class RTLResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, bool isRTL) builder;
  final bool reverseInRTL;

  const RTLResponsiveLayout({
    super.key,
    required this.builder,
    this.reverseInRTL = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, _) {
        final isRTL = localizationService.isRTL;
        return builder(context, isRTL);
      },
    );
  }
}

/// Extension methods for RTL-aware layouts
extension RTLExtension on Widget {
  /// Wrap widget with RTL support
  Widget withRTLSupport() => RTLWrapper(child: this);

  /// Wrap widget with forced RTL direction
  Widget withForcedRTL() => RTLWrapper(
        forceDirection: true,
        forcedDirection: TextDirection.rtl,
        child: this,
      );

  /// Wrap widget with forced LTR direction
  Widget withForcedLTR() => RTLWrapper(
        forceDirection: true,
        forcedDirection: TextDirection.ltr,
        child: this,
      );
}

/// Utility class for RTL-aware values
class RTLUtils {
  /// Get RTL-aware horizontal padding
  static EdgeInsets horizontalPadding({
    required double left,
    required double right,
    required BuildContext context,
  }) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    final isRTL = localizationService.isRTL;
    if (isRTL) {
      return EdgeInsets.only(left: right, right: left);
    }
    return EdgeInsets.only(left: left, right: right);
  }

  /// Get RTL-aware horizontal symmetric padding
  static EdgeInsets horizontalSymmetricPadding(
    double horizontal,
    BuildContext context,
  ) {
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  /// Get RTL-aware alignment
  static Alignment alignment({
    required Alignment ltr,
    required Alignment rtl,
    required BuildContext context,
  }) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL ? rtl : ltr;
  }

  /// Get RTL-aware start alignment
  static Alignment startAlignment(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL
        ? Alignment.centerRight
        : Alignment.centerLeft;
  }

  /// Get RTL-aware end alignment
  static Alignment endAlignment(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL
        ? Alignment.centerLeft
        : Alignment.centerRight;
  }

  /// Get RTL-aware border radius
  static BorderRadius horizontalBorderRadius({
    required double topLeft,
    required double topRight,
    required double bottomLeft,
    required double bottomRight,
    required BuildContext context,
  }) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    if (localizationService.isRTL) {
      return BorderRadius.only(
        topLeft: Radius.circular(topRight),
        topRight: Radius.circular(topLeft),
        bottomLeft: Radius.circular(bottomRight),
        bottomRight: Radius.circular(bottomLeft),
      );
    }
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }

  /// Get RTL-aware icon
  static IconData icon({
    required IconData ltr,
    required IconData rtl,
    required BuildContext context,
  }) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL ? rtl : ltr;
  }

  /// Get RTL-aware arrow icon
  static IconData arrowIcon(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL ? Icons.arrow_forward : Icons.arrow_back;
  }

  /// Get RTL-aware chevron icon
  static IconData chevronIcon(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    // RTL should point right, LTR should point left
    return localizationService.isRTL ? Icons.chevron_right : Icons.chevron_left;
  }

  /// Get RTL-aware text alignment
  static TextAlign textAlignment({
    required TextAlign ltr,
    required TextAlign rtl,
    required BuildContext context,
  }) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL ? rtl : ltr;
  }

  /// Get RTL-aware start text alignment
  static TextAlign startTextAlignment(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL ? TextAlign.right : TextAlign.left;
  }

  /// Get RTL-aware end text alignment
  static TextAlign endTextAlignment(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL ? TextAlign.left : TextAlign.right;
  }

  /// Get RTL-aware main axis alignment
  static MainAxisAlignment mainAxisAlignment({
    required MainAxisAlignment ltr,
    required MainAxisAlignment rtl,
    required BuildContext context,
  }) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL ? rtl : ltr;
  }

  /// Get RTL-aware start main axis alignment
  static MainAxisAlignment startMainAxisAlignment(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;
  }

  /// Get RTL-aware end main axis alignment
  static MainAxisAlignment endMainAxisAlignment(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL
        ? MainAxisAlignment.start
        : MainAxisAlignment.end;
  }

  /// Get RTL-aware cross axis alignment
  static CrossAxisAlignment crossAxisAlignment({
    required CrossAxisAlignment ltr,
    required CrossAxisAlignment rtl,
    required BuildContext context,
  }) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL ? rtl : ltr;
  }

  /// Get RTL-aware start cross axis alignment
  static CrossAxisAlignment startCrossAxisAlignment(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
  }

  /// Get RTL-aware end cross axis alignment
  static CrossAxisAlignment endCrossAxisAlignment(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end;
  }

  /// Reverse list if RTL
  static List<T> reverseIfRTL<T>(List<T> list, BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return localizationService.isRTL ? list.reversed.toList() : list;
  }

  /// Get RTL-aware margin
  static EdgeInsets margin({
    required double left,
    required double right,
    required BuildContext context,
  }) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    if (localizationService.isRTL) {
      return EdgeInsets.only(left: right, right: left);
    }
    return EdgeInsets.only(left: left, right: right);
  }

  /// Get RTL-aware padding
  static EdgeInsets padding({
    required double left,
    required double right,
    required BuildContext context,
  }) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    if (localizationService.isRTL) {
      return EdgeInsets.only(left: right, right: left);
    }
    return EdgeInsets.only(left: left, right: right);
  }
}
