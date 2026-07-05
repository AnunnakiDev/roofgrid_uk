import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/organisation/models/calculator_launch_options.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';

import 'package:roofgrid_uk/widgets/admin_access_guard.dart';

/// Maps a location to the main shell tab index (0–3).
int shellTabIndexFromLocation(String location) {
  if (location.startsWith('/calculator')) return 1;
  if (location.startsWith('/results')) return 2;
  if (location.startsWith('/tiles')) return 3;
  return 0;
}

const _proGatedPaths = ['/results', '/tiles'];

const labourCalculatorPath = '/labour-calculator';
const labourCalculatorUpsellPath = '/labour-calculator/upsell';
const customerQuoteUpsellPath = '/labour-calculator/customer-quote/upsell';
const customerQuotePreviewPath = '/labour-calculator/customer-quote/preview';

/// Resolves profile tab key from route query (`tab=labour-rates`, `tab=company`).
String? resolveProfileTabKey(String? tabParam) {
  if (tabParam == null || tabParam.isEmpty) return null;
  const known = {
    'account',
    'plan',
    'appearance',
    'company',
    'labour-rates',
    'admin',
  };
  if (known.contains(tabParam)) return tabParam;
  return switch (tabParam) {
    '0' => 'account',
    '1' => 'plan',
    '2' => 'appearance',
    '3' => 'company',
    '4' => 'labour-rates',
    '5' => 'admin',
    _ => null,
  };
}

bool isProGatedShellPath(String location) {
  return _proGatedPaths.any((path) => location.startsWith(path));
}

bool isLabourCalculatorPath(String location) {
  return location == labourCalculatorPath ||
      location.startsWith('$labourCalculatorPath/');
}

bool isCustomerQuotePath(String location) {
  return location == customerQuotePreviewPath ||
      location == customerQuoteUpsellPath;
}

/// Pure redirect resolver used by [goRouterProvider] and tests.
String? resolveAppRedirect({
  required String location,
  required bool isAuthenticated,
  required bool effectiveIsPro,
  UserModel? currentUser,
  bool canAccessLabourCalculator = false,
  bool canAccessCustomerQuote = false,
}) {
  final isSplash = location == '/splash';
  final isAuthRoute = location.startsWith('/auth');
  final isAdminRoute = location.startsWith('/admin');

  if (isSplash) {
    return isAuthenticated ? '/home' : '/auth/login';
  }

  if (!isAuthenticated && !isAuthRoute) {
    return '/auth/login';
  }

  final isForgotPassword = location == '/auth/forgot-password';
  if (isAuthenticated && isAuthRoute && !isForgotPassword) {
    return '/home';
  }

  if (isAdminRoute) {
    if (!isAuthenticated) {
      return '/auth/login';
    }
    if (currentUser != null && !isAdminUser(currentUser)) {
      return '/home';
    }
  }

  if (isAuthenticated &&
      !effectiveIsPro &&
      (location == '/results' || location == '/tiles')) {
    return '/subscription';
  }

  if (isAuthenticated && location == labourCalculatorPath) {
    if (!canAccessLabourCalculator) {
      return labourCalculatorUpsellPath;
    }
  }

  if (isAuthenticated && location == labourCalculatorUpsellPath) {
    if (canAccessLabourCalculator) {
      return labourCalculatorPath;
    }
  }

  if (isAuthenticated && location == customerQuotePreviewPath) {
    if (!canAccessLabourCalculator) {
      return labourCalculatorUpsellPath;
    }
    if (!canAccessCustomerQuote) {
      return customerQuoteUpsellPath;
    }
  }

  if (isAuthenticated && location == customerQuoteUpsellPath) {
    if (!canAccessLabourCalculator) {
      return labourCalculatorUpsellPath;
    }
    if (canAccessCustomerQuote) {
      return customerQuotePreviewPath;
    }
  }

  return null;
}

void showCustomerQuoteGateSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Customer Quote add-on required'),
    ),
  );
}

void navigateToCustomerQuotePreview(BuildContext context) {
  context.go(customerQuotePreviewPath);
}

void showLabourGateSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Labour Pricing Calculator add-on required'),
    ),
  );
}

void navigateToLabourCalculator(BuildContext context) {
  context.go(labourCalculatorPath);
}

void navigateToCalculator(
  BuildContext context, {
  SavedResult? savedResult,
  bool lockTileSpec = false,
  String? orgJobId,
}) {
  context.push(
    '/calculator',
    extra: CalculatorLaunchOptions(
      savedResult: savedResult,
      lockTileSpec: lockTileSpec,
      orgJobId: orgJobId,
    ),
  );
}

void navigateToLockedSetOutCalculator(
  BuildContext context, {
  required SavedResult savedResult,
  String? orgJobId,
}) {
  navigateToCalculator(
    context,
    savedResult: savedResult,
    lockTileSpec: true,
    orgJobId: orgJobId ?? savedResult.id,
  );
}

void navigateToLabourCalculatorWithJob(
  BuildContext context,
  String jobId, {
  bool canAccessLabour = true,
}) {
  final trimmed = jobId.trim();
  if (trimmed.isEmpty) {
    navigateToLabourCalculator(context);
    return;
  }
  if (!canAccessLabour) {
    showLabourGateSnackBar(context);
    context.go(labourCalculatorUpsellPath);
    return;
  }
  context.go('$labourCalculatorPath?jobId=$trimmed');
}

void showProGateSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Upgrade to Pro to access this feature'),
    ),
  );
}

/// Navigate to a shell tab, gating Results/Tiles for non-Pro users.
void navigateToShellTab(
  BuildContext context,
  WidgetRef ref,
  int index, {
  void Function(int index)? goBranch,
}) {
  if (index == 2 || index == 3) {
    final isPro = ref.read(effectiveIsProProvider);
    if (!isPro) {
      showProGateSnackBar(context);
      context.go('/subscription');
      return;
    }
  }

  if (goBranch != null) {
    goBranch(index);
    return;
  }

  switch (index) {
    case 0:
      context.go('/home');
    case 1:
      context.go('/calculator');
    case 2:
      context.go('/results');
    case 3:
      context.go('/tiles');
  }
}