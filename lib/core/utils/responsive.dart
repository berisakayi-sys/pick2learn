import 'package:flutter/widgets.dart';

/// Small helper for building responsive layouts that adapt to phones,
/// tablets, and desktops.
///
/// We use simple width breakpoints. Anything below [tabletBreakpoint] is a
/// phone; below [desktopBreakpoint] is a tablet; wider is a desktop.
class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= tabletBreakpoint && w < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  /// Returns a value based on the current screen size. Handy for choosing
  /// grid columns, paddings, etc.
  static T value<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? phone;
    if (isTablet(context)) return tablet ?? phone;
    return phone;
  }

  /// A sensible number of grid columns for the home feature buttons.
  static int gridColumns(BuildContext context) =>
      value(context, phone: 2, tablet: 3, desktop: 4);

  /// Constrains very wide content (desktop/web) to a comfortable reading width.
  static double contentMaxWidth(BuildContext context) =>
      isDesktop(context) ? 900 : double.infinity;
}
