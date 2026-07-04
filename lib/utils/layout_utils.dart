import 'package:flutter/material.dart';

/// Breakpoint matching phone / narrow wizard layouts (e.g. iPhone 17 Air Safari).
const double narrowLayoutBreakpoint = 600;

bool isNarrowLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width < narrowLayoutBreakpoint;
}

bool isNarrowLayoutWidth(double width) {
  return width < narrowLayoutBreakpoint;
}