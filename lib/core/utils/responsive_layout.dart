import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_dimens.dart';

/// Helper ringan untuk menjaga konten tetap nyaman di HP kecil dan tablet.
class ResponsiveLayout {
  ResponsiveLayout._();

  static bool isCompactWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 380;

  static bool isTabletWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 700;

  static bool isWideTabletWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  static double contentMaxWidth(BuildContext context) =>
      isWideTabletWidth(context) ? 980 : 760;

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final minPadding = width < 380 ? AppDimens.md : AppDimens.lg;
    final centeredPadding = (width - contentMaxWidth(context)) / 2;
    return math.max(minPadding, centeredPadding);
  }
}
