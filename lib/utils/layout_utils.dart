import 'package:flutter/material.dart';

/// Breakpoint matching phone / narrow wizard layouts.
const double narrowLayoutBreakpoint = 600;

/// Very small phones (stack filters, tighter grids).
const double compactPhoneBreakpoint = 400;

/// Tablet portrait and below use step-based labour wizard.
const double tabletBreakpoint = 900;

const double _contentMaxWidth = 720;

bool isNarrowLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width < narrowLayoutBreakpoint;
}

bool isNarrowLayoutWidth(double width) {
  return width < narrowLayoutBreakpoint;
}

bool isCompactPhone(BuildContext context) {
  return MediaQuery.sizeOf(context).width < compactPhoneBreakpoint;
}

bool useLabourWizardLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width < tabletBreakpoint;
}

double screenHorizontalPadding(BuildContext context) {
  if (isCompactPhone(context)) return 12;
  if (isNarrowLayout(context)) return 16;
  return 20;
}

double? screenContentMaxWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= narrowLayoutBreakpoint && width < tabletBreakpoint) {
    return _contentMaxWidth;
  }
  if (width >= tabletBreakpoint) {
    return _contentMaxWidth;
  }
  return null;
}

Widget constrainContentWidth(BuildContext context, Widget child) {
  final maxWidth = screenContentMaxWidth(context);
  if (maxWidth == null) return child;
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}